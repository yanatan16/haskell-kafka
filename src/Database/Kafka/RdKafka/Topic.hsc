{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Topic (
  RdKafkaTopic, RdKafkaTopicRaw,
  newTopic,
  topicName,
  wrapTopicRaw
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Database.Kafka.RdKafka.Kafka (RdKafka, RdKafkaRaw)
import Database.Kafka.RdKafka.TopicConf (RdKafkaTopicConf, RdKafkaTopicConfRaw)

#include <librdkafka/rdkafka.h>

-----------
-- Topics
-----------

data RdKafkaTopicBase
type RdKafkaTopicRaw = Ptr RdKafkaTopicBase
type RdKafkaTopic = ForeignPtr RdKafkaTopicBase


foreign import ccall unsafe "rdkafka.h &rd_kafka_topic_destroy"
  c_rd_kafka_topic_destroy :: FunPtr (RdKafkaTopicRaw -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_new"
  c_rd_kafka_topic_new :: RdKafkaRaw
                       -> CString
                       -> RdKafkaTopicConfRaw
                       -> IO RdKafkaTopicRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_name"
  c_rd_kafka_topic_name :: RdKafkaTopicRaw
                        -> CString

newTopic :: RdKafka -> String -> RdKafkaTopicConf -> RdKafkaTopic
newTopic k t conf = unsafePerformIO $ withCString t $ \ct ->
  withForeignPtr k $ \rk ->
    withForeignPtr conf $ \rconf -> do
      ptr <- c_rd_kafka_topic_new rk ct rconf
      wrapTopicRaw ptr

topicName :: RdKafkaTopic -> String
topicName rkt = unsafePerformIO $ withForeignPtr rkt (peekCString . c_rd_kafka_topic_name)

wrapTopicRaw :: RdKafkaTopicRaw -> IO RdKafkaTopic
wrapTopicRaw = newForeignPtr c_rd_kafka_topic_destroy