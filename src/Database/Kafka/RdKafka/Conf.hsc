{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Confs (
  RdKafkaConfResponse,
  conf_res_unknown, conf_res_invalid, conf_res_ok
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types (CInt)

#include <librdkafka/rdkafka.h>

newtype RdKafkaConfResponse = RdKafkaConfResponse { unRdKafkaConfResponse :: CInt }
#{enum RdKafkaConfResponse, RdKafkaConfResponse
  , conf_res_unknown = RD_KAFKA_CONF_UNKNOWN
  , conf_res_invalid = RD_KAFKA_CONF_INVALID
  , conf_res_ok = RD_KAFKA_CONF_OK}

instance Show RdKafkaConfResponse where
  show conf_res_unknown = "Unknown Configuration Key"
  show conf_res_invalid = "Invalid Configuration Value"
  show conf_res_ok = "OK"