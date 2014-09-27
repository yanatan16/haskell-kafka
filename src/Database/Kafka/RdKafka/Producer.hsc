{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Producer (
  produce
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String

import Control.Applicative ((<$>))

import Database.Kafka.RdKafka.Errors (RdKafkaError(..), error_no_error, errnoDesc)
import Database.Kafka.RdKafka.Topic (RdKafkaTopic, RdKafkaTopicRaw)
import Database.Kafka.RdKafka.Message (RdKafkaMessage)
import Database.Kafka.RdKafka.Headers (RdKafkaOffset(..), RdKafkaPartition(..))

#include <librdkafka/rdkafka.h>

newtype RdKafkaMessageFlags = RdKafkaMessageFlags CInt
#{enum RdKafkaMessageFlags, RdKafkaMessageFlags
  , message_free = RD_KAFKA_MSG_F_FREE
  , message_copy = RD_KAFKA_MSG_F_COPY}

foreign import ccall unsafe "rdkafka.h rd_kafka_offset_store"
  c_rd_kafka_produce :: RdKafkaTopicRaw
                     -> RdKafkaPartition
                     -> RdKafkaMessageFlags
                     -> CString -> CSize
                     -> CString -> CSize
                     -> Ptr ()
                     -> IO RdKafkaError

produce :: RdKafkaTopic
        -> RdKafkaPartition
        -> String
        -> String
        -> IO (Either String ())
produce t p pay key = withForeignPtr t $ \t_raw ->
  withCStringLen pay $ \(cpay, payl) ->
  withCStringLen key $ \(ckey, keyl) -> do
    let cpayl = fromIntegral payl
    let ckeyl = fromIntegral keyl
    err <- c_rd_kafka_produce t_raw p message_copy cpay cpayl ckey ckeyl nullPtr
    case err of
      error_no_error -> Right <$> return ()
      otherwise      -> Left <$> errnoDesc