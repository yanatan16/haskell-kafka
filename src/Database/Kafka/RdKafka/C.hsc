{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.C where

import Foreign
import Foreign.C.Types
import Foreign.C.String

#include <librdkafka/rdkafka.h>

foreign import ccall unsafe "rdkafka.h rd_kafka_version_str"
    c_rd_kafka_version_str  :: IO CString

version :: String
version = unsafePerformIO $ peekCString =<< c_rd_kafka_version_str