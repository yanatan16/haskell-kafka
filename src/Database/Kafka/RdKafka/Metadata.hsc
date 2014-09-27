{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Metadata (
  RdKafkaMetadataBroker,
  RdKafkaMetadataPartition,
  RdKafkaMetadataTopic,
  RdKafkaMetadata,
  retrieveMetadataTopic,
  retrieveMetadataAll,
  retrieveMetadataLocal
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String

import Control.Applicative ((<$>))

import Database.Kafka.RdKafka.Headers (TimeoutMs(..))
import Database.Kafka.RdKafka.Kafka (RdKafka, RdKafkaRaw)
import Database.Kafka.RdKafka.Topic (RdKafkaTopic, RdKafkaTopicRaw)
import Database.Kafka.RdKafka.Errors (RdKafkaError(..), errorToString)

#include <librdkafka/rdkafka.h>
#let alignment t = "%lu", (unsigned long)offsetof(struct {char x__; t (y__); }, y__)

data RdKafkaMetadataBroker = RdKafkaMetadataBroker {
  broker_id :: CInt,
  broker_host :: CString,
  broker_port :: CInt
}

data RdKafkaMetadataPartition = RdKafkaMetadataPartition {
  partition_id :: CInt,
  partition_err :: RdKafkaError,
  partition_leader :: CInt,
  partition_replicas :: [CInt],
  partition_isrs :: [CInt]
}

data RdKafkaMetadataTopic = RdKafkaMetadataTopic {
  topic_topic :: CString,
  topic_partitions :: [RdKafkaMetadataPartition],
  topic_err :: RdKafkaError
}

data RdKafkaMetadata = RdKafkaMetadata {
  metadata_brokers :: [RdKafkaMetadataBroker],
  metadata_topics :: [RdKafkaMetadataTopic],
  metadata_orig_broker_id :: CInt,
  metadata_orig_broker_name :: CString
}

instance Storable RdKafkaMetadataBroker where
  alignment _ = #{alignment rd_kafka_metadata_broker_t}
  sizeOf _ = #{size rd_kafka_metadata_broker_t}
  peek ptr = do
    id <- #{peek rd_kafka_metadata_broker_t, id} ptr
    host <- #{peek rd_kafka_metadata_broker_t, host} ptr
    port <- #{peek rd_kafka_metadata_broker_t, port} ptr
    return $ RdKafkaMetadataBroker id host port
  poke ptr (RdKafkaMetadataBroker id host port) = do
    #{poke rd_kafka_metadata_broker_t, id} ptr id
    #{poke rd_kafka_metadata_broker_t, host} ptr host
    #{poke rd_kafka_metadata_broker_t, port} ptr port

instance Storable RdKafkaMetadataPartition where
  alignment _ = #{alignment rd_kafka_metadata_partition_t}
  sizeOf _ = #{size rd_kafka_metadata_partition_t}
  peek ptr = do
    id <- #{peek rd_kafka_metadata_partition_t, id} ptr
    err <- #{peek rd_kafka_metadata_partition_t, err} ptr
    leader <- #{peek rd_kafka_metadata_partition_t, leader} ptr
    replica_cnt <- #{peek rd_kafka_metadata_partition_t, replica_cnt} ptr
    replicas <- #{peek rd_kafka_metadata_partition_t, replicas} ptr
    isr_cnt <- #{peek rd_kafka_metadata_partition_t, isr_cnt} ptr
    isrs <- #{peek rd_kafka_metadata_partition_t, isrs} ptr

    replicas' <- peekArray replicas replica_cnt
    isrs' <- peekArray isrs isr_cnt

    return $ RdKafkaMetadataPartition id err leader replicas' isrs'
  poke ptr (RdKafkaMetadataPartition id err leader replicas' isrs') = do
    replicas <- newArray replicas'
    isrs <- newArray isrs'

    #{poke rd_kafka_metadata_partition_t, id} ptr id
    #{poke rd_kafka_metadata_partition_t, err} ptr err
    #{poke rd_kafka_metadata_partition_t, leader} ptr leader
    #{poke rd_kafka_metadata_partition_t, replica_cnt} ptr (length replicas')
    #{poke rd_kafka_metadata_partition_t, replicas} ptr replicas
    #{poke rd_kafka_metadata_partition_t, isr_cnt} ptr (length isrs')
    #{poke rd_kafka_metadata_partition_t, isrs} ptr isrs


instance Storable RdKafkaMetadataTopic where
  alignment _ = #{alignment rd_kafka_metadata_topic_t}
  sizeOf _ = #{size rd_kafka_metadata_topic_t}
  peek ptr = do
    topic <- #{peek rd_kafka_metadata_topic_t, topic} ptr
    partition_cnt <- #{peek rd_kafka_metadata_topic_t, partition_cnt} ptr
    partitions <- #{peek rd_kafka_metadata_topic_t, partitions} ptr
    err <- #{peek rd_kafka_metadata_topic_t, err} ptr

    partitions' <- peekArray partitions partition_cnt

    return $ RdKafkaMetadataTopic topic partitions' err
  poke ptr (RdKafkaMetadataTopic topic partitions' err) = do
    partitions <- newArray partitions'

    #{poke rd_kafka_metadata_topic_t, topic} ptr topic
    #{poke rd_kafka_metadata_topic_t, partition_cnt} ptr (length partitions')
    #{poke rd_kafka_metadata_topic_t, partitions} ptr partitions
    #{poke rd_kafka_metadata_topic_t, err} ptr err

instance Storable RdKafkaMetadata where
  alignment _ = #{alignment rd_kafka_metadata_t}
  sizeOf _ = #{size rd_kafka_metadata_t}
  peek ptr = do
    broker_cnt <- #{peek rd_kafka_metadata_t, broker_cnt} ptr
    brokers <- #{peek rd_kafka_metadata_t, brokers} ptr
    topic_cnt <- #{peek rd_kafka_metadata_t, topic_cnt} ptr
    topics <- #{peek rd_kafka_metadata_t, topics} ptr
    orig_broker_id <- #{peek rd_kafka_metadata_t, orig_broker_id} ptr
    orig_broker_name <- #{peek rd_kafka_metadata_t, orig_broker_name} ptr

    brokers' <- peekArray brokers broker_cnt
    topics' <- peekArray topics topic_cnt

    return $ RdKafkaMetadata brokers' topics' orig_broker_id orig_broker_name
  poke ptr (RdKafkaMetadata brokers' topics' orig_broker_id orig_broker_name) = do
    brokers <- newArray brokers'
    topics <- newArray topics'

    #{poke rd_kafka_metadata_t, broker_cnt} ptr (length brokers')
    #{poke rd_kafka_metadata_t, brokers} ptr brokers
    #{poke rd_kafka_metadata_t, topic_cnt} ptr (length topics')
    #{poke rd_kafka_metadata_t, topics} ptr topics
    #{poke rd_kafka_metadata_t, orig_broker_id} ptr orig_broker_id
    #{poke rd_kafka_metadata_t, orig_broker_name} ptr orig_broker_name

newtype AllTopicsFlag = AllTopicsFlag CInt
all_topics = AllTopicsFlag 1
local_topics = AllTopicsFlag 0

foreign import ccall unsafe "rdkafka.h rd_kafka_metadata"
  c_rd_kafka_metadata :: RdKafkaRaw
                      -> AllTopicsFlag
                      -> RdKafkaTopicRaw
                      -> Ptr (Ptr RdKafkaMetadata)
                      -> TimeoutMs
                      -> IO RdKafkaError

foreign import ccall unsafe "rdkafka.h rd_kafka_metadata_destroy"
  c_rd_kafka_metadata_destroy :: Ptr RdKafkaMetadata -> IO ()

retrieveMetadata :: RdKafka -> Maybe RdKafkaTopic -> AllTopicsFlag -> TimeoutMs -> IO (Either String RdKafkaMetadata)
retrieveMetadata k rkt atf tms = withForeignPtr k $ \kraw ->
  withMaybeForeignPtr rkt $ \rktraw ->
    alloca $ \ptrRkm -> do
      err <- c_rd_kafka_metadata kraw atf rktraw ptrRkm tms
      case err of
        error_no_error -> do
          rkmb <- peek ptrRkm
          rkm <- peek rkmb
          c_rd_kafka_metadata_destroy rkmb
          return $ Right rkm
        otherwise -> return $ Left (errorToString err)

retrieveMetadataTopic :: RdKafka -> RdKafkaTopic -> TimeoutMs -> IO (Either String RdKafkaMetadata)
retrieveMetadataTopic k t = retrieveMetadata k (Just t) local_topics

retrieveMetadataAll :: RdKafka -> TimeoutMs -> IO (Either String RdKafkaMetadata)
retrieveMetadataAll k = retrieveMetadata k Nothing all_topics

retrieveMetadataLocal :: RdKafka -> TimeoutMs -> IO (Either String RdKafkaMetadata)
retrieveMetadataLocal k = retrieveMetadata k Nothing local_topics

withMaybeForeignPtr :: Maybe (ForeignPtr a) -> (Ptr a -> IO b) -> IO b
withMaybeForeignPtr Nothing f    = f nullPtr
withMaybeForeignPtr (Just fpa) f = withForeignPtr fpa f