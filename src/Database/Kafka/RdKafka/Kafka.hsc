{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Kafka (
  RdKafka, RdKafkaRaw,
  newKafka,
  kafkaHandleName,

  RdKafkaType, producer_mode, consumer_mode
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Control.Applicative ((<$>), (<*>))

import Database.Kafka.RdKafka.Conf (RdKafkaConf, RdKafkaConfRaw)
import Database.Kafka.RdKafka.Errors (withErrorBuffer)

#include <librdkafka/rdkafka.h>


-- Kafka Modes
newtype RdKafkaType = RdKafkaType CInt
  deriving (Show)
#{enum RdKafkaType, RdKafkaType
  , producer_mode       = RD_KAFKA_PRODUCER
  , consumer_mode       = RD_KAFKA_CONSUMER}


-- Kafka Instance

data RdKafkaBase
type RdKafkaRaw = Ptr RdKafkaBase
type RdKafka = ForeignPtr RdKafkaBase

foreign import ccall unsafe "rdkafka.h &rd_kafka_destroy"
  c_rd_kafka_destroy :: FunPtr (RdKafkaRaw -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_new"
  c_rd_kafka_new :: RdKafkaType
                 -> RdKafkaConfRaw
                 -> CString
                 -> CSize
                 -> IO RdKafkaRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_name"
  c_rd_kafka_name :: RdKafkaRaw -> CString

foreign import ccall unsafe "rdkafka.h rd_kafka_outq_len"
  c_rd_kafka_outq_len :: RdKafkaRaw -> IO CInt

wrapKafkaPtr :: RdKafkaRaw -> IO RdKafka
wrapKafkaPtr = newForeignPtr c_rd_kafka_destroy

newKafka :: RdKafkaType -> RdKafkaConf -> Either String RdKafka
newKafka typ conf = unsafePerformIO $
  withForeignPtr conf $ \rconf ->
  withErrorBuffer $ \(errstr, errlen) -> do
    ptr <- c_rd_kafka_new typ rconf errstr (fromIntegral errlen)
    if ptr == nullPtr
      then Left <$> peekCStringLen (errstr, errlen)
      else Right <$> wrapKafkaPtr ptr

kafkaHandleName :: RdKafka -> String
kafkaHandleName rk = unsafePerformIO $ withForeignPtr rk (peekCString . c_rd_kafka_name)

outputQueueLength :: RdKafka -> Int
outputQueueLength rk = unsafePerformIO $ withForeignPtr rk $ \rkr -> fromIntegral <$> (c_rd_kafka_outq_len rkr)