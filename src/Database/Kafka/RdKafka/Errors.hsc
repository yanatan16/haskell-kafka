{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Errors (
  KafkaError (),
  errorToString, errnoToString,

  error_begin, error_bad_msg, error_bad_compression, error_destroy, error_fail, error_transport, error_crit_sys_resource,
  error_resolve, error_msg_timed_out, error_partition_eof, error_unknown_partition, error_fs, error_unknown_topic, error_all_brokers_down,
  error_invalid_arg, error_timed_out, error_queue_full, error_isr_insuff, error_end, error_unknown, error_no_error, error_offset_out_of_range,
  error_invalid_msg, error_unknown_topic_or_part, error_invalid_msg_size, error_leader_not_available, error_not_leader_for_partition,
  error_request_timed_out, error_broker_not_available, error_replica_not_available, error_msg_size_too_large, error_stale_ctrl_epoch,
  error_offset_metadata_too_large
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types (CInt(..))
import Foreign.C.String (CString, peekCString)
import Foreign.C.Error (Errno(..))
import System.IO.Unsafe (unsafePerformIO)

#include <librdkafka/rdkafka.h>

-- Kafka Errors

newtype KafkaError = KafkaError { unKafkaError :: CInt }
  deriving (Show,Eq)

foreign import ccall unsafe "rdkafka.h rd_kafka_err2str"
  c_rd_kafka_err2str :: KafkaError -> CString

foreign import ccall unsafe "rdkafka.h rd_kafka_errno2err"
  c_rd_kafka_errno2err :: Errno -> KafkaError

errorToString :: KafkaError -> String
errorToString err = unsafePerformIO $ peekCString $ c_rd_kafka_err2str err

errnoToString :: Errno -> String
errnoToString = unsafePerformIO . peekCString . c_rd_kafka_err2str . c_rd_kafka_errno2err

#{enum KafkaError, KafkaError
  , error_begin = RD_KAFKA_RESP_ERR__BEGIN
  , error_bad_msg = RD_KAFKA_RESP_ERR__BAD_MSG
  , error_bad_compression = RD_KAFKA_RESP_ERR__BAD_COMPRESSION
  , error_destroy = RD_KAFKA_RESP_ERR__DESTROY
  , error_fail = RD_KAFKA_RESP_ERR__FAIL
  , error_transport = RD_KAFKA_RESP_ERR__TRANSPORT
  , error_crit_sys_resource = RD_KAFKA_RESP_ERR__CRIT_SYS_RESOURCE
  , error_resolve = RD_KAFKA_RESP_ERR__RESOLVE
  , error_msg_timed_out = RD_KAFKA_RESP_ERR__MSG_TIMED_OUT
  , error_partition_eof = RD_KAFKA_RESP_ERR__PARTITION_EOF
  , error_unknown_partition = RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION
  , error_fs = RD_KAFKA_RESP_ERR__FS
  , error_unknown_topic = RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC
  , error_all_brokers_down = RD_KAFKA_RESP_ERR__ALL_BROKERS_DOWN
  , error_invalid_arg = RD_KAFKA_RESP_ERR__INVALID_ARG
  , error_timed_out = RD_KAFKA_RESP_ERR__TIMED_OUT
  , error_queue_full = RD_KAFKA_RESP_ERR__QUEUE_FULL
  , error_isr_insuff = RD_KAFKA_RESP_ERR__ISR_INSUFF
  , error_end = RD_KAFKA_RESP_ERR__END

  , error_unknown = RD_KAFKA_RESP_ERR_UNKNOWN
  , error_no_error = RD_KAFKA_RESP_ERR_NO_ERROR
  , error_offset_out_of_range = RD_KAFKA_RESP_ERR_OFFSET_OUT_OF_RANGE
  , error_invalid_msg = RD_KAFKA_RESP_ERR_INVALID_MSG
  , error_unknown_topic_or_part = RD_KAFKA_RESP_ERR_UNKNOWN_TOPIC_OR_PART
  , error_invalid_msg_size = RD_KAFKA_RESP_ERR_INVALID_MSG_SIZE
  , error_leader_not_available = RD_KAFKA_RESP_ERR_LEADER_NOT_AVAILABLE
  , error_not_leader_for_partition = RD_KAFKA_RESP_ERR_NOT_LEADER_FOR_PARTITION
  , error_request_timed_out = RD_KAFKA_RESP_ERR_REQUEST_TIMED_OUT
  , error_broker_not_available = RD_KAFKA_RESP_ERR_BROKER_NOT_AVAILABLE
  , error_replica_not_available = RD_KAFKA_RESP_ERR_REPLICA_NOT_AVAILABLE
  , error_msg_size_too_large = RD_KAFKA_RESP_ERR_MSG_SIZE_TOO_LARGE
  , error_stale_ctrl_epoch = RD_KAFKA_RESP_ERR_STALE_CTRL_EPOCH
  , error_offset_metadata_too_large = RD_KAFKA_RESP_ERR_OFFSET_METADATA_TOO_LARGE}