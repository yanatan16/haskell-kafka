{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Headers (
  version,

  RdKafkaMode (),
  producer_mode, consumer_mode
) where

import Foreign ()
import Foreign.C.Types (CInt)
import Foreign.C.String (CString, peekCString)
import System.IO.Unsafe (unsafePerformIO)

#include <librdkafka/rdkafka.h>

----------
-- Version
----------

foreign import ccall unsafe "rdkafka.h rd_kafka_version_str"
  c_rd_kafka_version_str  :: CString

version :: String
version = unsafePerformIO $ peekCString $ c_rd_kafka_version_str

-----------------
-- Kafka Instance
-----------------

-- Kafka Modes
newtype RdKafkaMode = RdKafkaMode { unRdKafkaMode :: CInt }
  deriving (Show)
#{enum RdKafkaMode, RdKafkaMode
  , producer_mode       = RD_KAFKA_PRODUCER
  , consumer_mode       = RD_KAFKA_CONSUMER
  }

