{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Topic (
) where

import Foreign (ForeignPtr)
import Foreign.C.Types (CInt, CLong, CSize)
import Foreign.C.String (CString, peekCString)
import Foreign.Ptr (Ptr, nullPtr)
import System.IO.Unsafe (unsafePerformIO)

import Database.Kafka.RdKafka.Errors (RdKafkaError)
import Database.Kafka.RdKafka.Headers (RdKafkaPtr)

#include <librdkafka/rdkafka.h>

-----------
-- Topics
-----------

newtype RdKafkaTopic
type RdKafkaTopicPtr = ForeignPtr RdKafkaTopic
newtype RdKafkaTopicConf
type RdKafkaTopicConfPtr = ForeignPtr RdKafkaTopicConf


foreign import ccall unsafe "rdkafka.h &rd_kafka_topic_destroy"
  c_rd_kafka_topic_destroy :: FunPtr (Ptr RdKafkaTopic -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_new"
  c_rd_kafka_topic_new :: RdKafkaPtr
                       -> String
                       -> RdKafkaTopicConfPtr
                       -> IO (Ptr RdKafkaTopic)

foreign import ccall unsafe "rdkafka.h &rd_kafka_topic_conf_destroy"
  c_rd_kafka_topic_conf_destroy :: FunPtr (Ptr RdKafkaTopicConf -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_new"
  c_rd_kafka_topic_conf_new :: IO (Ptr RdKafkaTopicConf)

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_new"
  c_rd_kafka_topic_conf_new :: RdKafkaTopicConfPtr -> IO (Ptr RdKafkaTopicConf)


