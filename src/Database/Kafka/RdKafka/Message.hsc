{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Message (
  RdKafkaMessage(..),
  wrapMessageRaw,
  parseMessage
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Control.Applicative ((<$>))
import Database.Kafka.RdKafka.Errors (RdKafkaError)
import Database.Kafka.RdKafka.Topic (RdKafkaTopicRaw)
import Database.Kafka.RdKafka.Headers (RdKafkaPartition, RdKafkaOffset)

#include <librdkafka/rdkafka.h>
#let alignment t = "%lu", (unsigned long)offsetof(struct {char x__; t (y__); }, y__)

-----------
-- Messages
-----------

data ArbitraryRegion
type ArbitraryPtr = Ptr ArbitraryRegion

data RdKafkaMessage = RdKafkaMessage {
  rd_kafka_message_err :: RdKafkaError,
  rd_kafka_message_topic :: RdKafkaTopicRaw,
  rd_kafka_message_partition :: RdKafkaPartition,
  rd_kafka_message_payload :: CStringLen,
  rd_kafka_message_key :: CStringLen,
  rd_kafka_message_offset :: RdKafkaOffset
}
type RdKafkaMessageRaw = Ptr RdKafkaMessage
type RdKafkaMessagePtr = ForeignPtr RdKafkaMessage

instance Storable RdKafkaMessage where
  alignment _ = #{alignment rd_kafka_message_t}
  sizeOf _ = #{size rd_kafka_message_t}
  peek ptr = do
    err <- #{peek rd_kafka_message_t, err} ptr
    rkt <- #{peek rd_kafka_message_t, rkt} ptr
    partition <- #{peek rd_kafka_message_t, partition} ptr
    payload <- #{peek rd_kafka_message_t, payload} ptr
    len <- #{peek rd_kafka_message_t, len} ptr
    key <- #{peek rd_kafka_message_t, key} ptr
    key_len <- #{peek rd_kafka_message_t, key_len} ptr
    offset <- #{peek rd_kafka_message_t, offset} ptr
    #{peek rd_kafka_message_t, _private} ptr :: IO ArbitraryPtr

    let csl_payload = (payload, len)
    let csl_key = (key, key_len)
    return $ RdKafkaMessage err rkt partition csl_payload csl_key offset

  poke ptr (RdKafkaMessage err rkt partition csl_payload csl_key offset) = do
    #{poke rd_kafka_message_t, err} ptr err
    #{poke rd_kafka_message_t, rkt} ptr rkt
    #{poke rd_kafka_message_t, partition} ptr partition
    #{poke rd_kafka_message_t, payload} ptr (fst csl_payload)
    #{poke rd_kafka_message_t, len} ptr (fromIntegral $ snd csl_payload :: CInt)
    #{poke rd_kafka_message_t, key} ptr (fst csl_key)
    #{poke rd_kafka_message_t, key_len} ptr (fromIntegral $ snd csl_key :: CInt)
    #{poke rd_kafka_message_t, offset} ptr offset
    #{poke rd_kafka_message_t, _private} ptr nullPtr


foreign import ccall unsafe "rdkafka.h &rd_kafka_message_destroy"
  c_rd_kafka_message_destroy :: FunPtr (RdKafkaMessageRaw -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_message_errstr"
  c_rd_kafka_message_errstr :: RdKafkaMessageRaw -> CString

wrapMessageRaw :: RdKafkaMessageRaw -> IO RdKafkaMessagePtr
wrapMessageRaw = newForeignPtr c_rd_kafka_message_destroy

parseMessage :: RdKafkaMessagePtr -> Either String RdKafkaMessage
parseMessage m = unsafePerformIO $ withForeignPtr m $ \rm -> do
    let cerrstr = c_rd_kafka_message_errstr rm
    case cerrstr of
      nullPtr   -> Right <$> peek rm
      otherwise -> Left <$> peekCString cerrstr
