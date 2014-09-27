{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Headers (
  version,
  RdKafkaPartition(..), partition_unassigned,
  RdKafkaOffset(..), offset_beginning, offset_end, offset_stored,
  TimeoutMs(..)
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Data.Typeable (Typeable)

#include <librdkafka/rdkafka.h>

newtype TimeoutMs = TimeoutMs CInt
  deriving (Show, Read, Eq, Ord, Enum, Num, Real, Integral)

----------
-- Version
----------

foreign import ccall unsafe "rdkafka.h rd_kafka_version_str"
  c_rd_kafka_version_str  :: CString

version :: String
version = unsafePerformIO $ peekCString c_rd_kafka_version_str


--- Partition

newtype RdKafkaPartition = RdKafkaPartition CInt
  deriving (Show, Eq, Storable)

#{enum RdKafkaPartition, RdKafkaPartition
  , partition_unassigned = RD_KAFKA_PARTITION_UA}

--- Offset

newtype RdKafkaOffset = RdKafkaOffset CLong
  deriving (Show, Eq, Ord, Storable)

#{enum RdKafkaOffset, RdKafkaOffset
  , offset_beginning = RD_KAFKA_OFFSET_BEGINNING
  , offset_end = RD_KAFKA_OFFSET_END
  , offset_stored = RD_KAFKA_OFFSET_STORED}