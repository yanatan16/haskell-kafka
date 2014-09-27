{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Consumer (
  consumeStart, consumeStop, consume, storeOffset,
  RdKafkaMessageHandler
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import Foreign.C.Error
import System.IO.Unsafe (unsafePerformIO)

import Control.Applicative ((<$>), (<*>))

import Database.Kafka.RdKafka.Errors (RdKafkaError(..), error_no_error, errnoDesc)
import Database.Kafka.RdKafka.Topic (RdKafkaTopic, RdKafkaTopicRaw)
import Database.Kafka.RdKafka.Message (RdKafkaMessage)
import Database.Kafka.RdKafka.Headers (RdKafkaOffset(..), RdKafkaPartition(..), TimeoutMs(..))

#include <librdkafka/rdkafka.h>

type RdKafkaMessageHandler = RdKafkaMessage -> IO ()
type RdKafkaMessageHandlerRaw = Ptr RdKafkaMessage -> Ptr () -> IO ()

foreign import ccall unsafe "rdkafka.h rd_kafka_consume_start"
  c_rd_kafka_consume_start :: RdKafkaTopicRaw
                           -> RdKafkaPartition
                           -> RdKafkaOffset
                           -> IO RdKafkaError

foreign import ccall unsafe "rdkafka.h rd_kafka_consume_stop"
  c_rd_kafka_consume_stop :: RdKafkaTopicRaw
                          -> RdKafkaPartition
                          -> IO RdKafkaError

-- the fastest of the consuming functions
foreign import ccall safe "rdkafka.h rd_kafka_consume_callback"
  c_rd_kafka_consume_callback :: RdKafkaTopicRaw
                              -> RdKafkaPartition
                              -> TimeoutMs
                              -> FunPtr RdKafkaMessageHandlerRaw
                              -> Ptr ()
                              -> IO RdKafkaError

foreign import ccall unsafe "rdkafka.h rd_kafka_offset_store"
  c_rd_kafka_offset_store :: RdKafkaTopicRaw
                          -> RdKafkaPartition
                          -> RdKafkaOffset
                          -> IO RdKafkaError

foreign import ccall safe "wrapper"
  wrapMessageHandlerRaw :: RdKafkaMessageHandlerRaw -> IO (FunPtr RdKafkaMessageHandlerRaw)

withFunPtr :: a -> (a -> IO (FunPtr a)) -> (FunPtr a -> IO b) -> IO b
withFunPtr a w f = do
  fp <- w a
  res <- f fp
  freeHaskellFunPtr fp
  return res

withMessageHandlerRaw :: RdKafkaMessageHandlerRaw -> (FunPtr RdKafkaMessageHandlerRaw -> IO a) -> IO a
withMessageHandlerRaw h = withFunPtr h wrapMessageHandlerRaw

mkMessageHandlerRaw :: RdKafkaMessageHandler -> RdKafkaMessageHandlerRaw
mkMessageHandlerRaw h = \m _ -> peek m >>= h

withMessageHandler :: RdKafkaMessageHandler -> (FunPtr RdKafkaMessageHandlerRaw -> IO a) -> IO a
withMessageHandler h f = withMessageHandlerRaw (mkMessageHandlerRaw h) f

consumeStart :: RdKafkaTopic -> RdKafkaPartition -> RdKafkaOffset -> IO RdKafkaError
consumeStart rkt rkp rko = withForeignPtr rkt $ \rkt_raw -> c_rd_kafka_consume_start rkt_raw rkp rko

consumeStop :: RdKafkaTopic -> RdKafkaPartition  -> IO RdKafkaError
consumeStop rkt rkp = withForeignPtr rkt $ \rkt_raw -> c_rd_kafka_consume_stop rkt_raw rkp

consume :: RdKafkaTopic
        -> RdKafkaPartition
        -> TimeoutMs
        -> RdKafkaMessageHandler
        -> IO (Either String ())
consume t p tm f = withForeignPtr t $ \traw ->
  withMessageHandler f $ \h -> do
    err <- c_rd_kafka_consume_callback traw p tm h nullPtr
    case err of
      error_no_error -> Right <$> return ()
      otherwise      -> Left <$> errnoDesc

storeOffset :: RdKafkaTopic -> RdKafkaPartition -> RdKafkaOffset -> IO RdKafkaError
storeOffset rkt rkp rko = withForeignPtr rkt $ \rkt_raw -> c_rd_kafka_offset_store rkt_raw rkp rko