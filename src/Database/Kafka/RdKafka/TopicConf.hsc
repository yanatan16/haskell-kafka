{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.TopicConf (
  RdKafkaTopicConf, RdKafkaTopicConfRaw,
  newTopicConf,
  assocTopicConf
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Control.Monad (foldM)
import Control.Applicative ((<$>), (<*>))

import Database.Kafka.RdKafka.Errors (withErrorBuffer)
import Database.Kafka.RdKafka.Conf (RdKafkaConfResponse(..), conf_res_ok)

#include <librdkafka/rdkafka.h>

data RdKafkaTopicConfBase
type RdKafkaTopicConfRaw = Ptr RdKafkaTopicConfBase
type RdKafkaTopicConf = ForeignPtr RdKafkaTopicConfBase

foreign import ccall unsafe "rdkafka.h &rd_kafka_topic_conf_destroy"
  c_rd_kafka_topic_conf_destroy :: FunPtr (RdKafkaTopicConfRaw -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_new"
  c_rd_kafka_topic_conf_new :: IO RdKafkaTopicConfRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_dup"
  c_rd_kafka_topic_conf_dup :: RdKafkaTopicConfRaw -> IO RdKafkaTopicConfRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_set"
  c_rd_kafka_topic_conf_set :: RdKafkaTopicConfRaw
                            -> CString
                            -> CString
                            -> CString
                            -> CSize
                            -> IO RdKafkaConfResponse

wrapTopicConfPtr :: RdKafkaTopicConfRaw -> IO RdKafkaTopicConf
wrapTopicConfPtr = newForeignPtr c_rd_kafka_topic_conf_destroy

setTopicConfKV :: RdKafkaTopicConf -> String -> String -> CStringLen -> IO RdKafkaConfResponse
setTopicConfKV tcnf k v (errstr, errlen) = withForeignPtr tcnf $ \rtcnf ->
  withCString k $ \ck ->
  withCString v $ \cv ->
    c_rd_kafka_topic_conf_set rtcnf ck cv errstr (fromIntegral errlen)

setTopicConfMult :: [(String, String)] -> RdKafkaTopicConf -> IO (Either String RdKafkaTopicConf)
setTopicConfMult kv tc = withErrorBuffer $ \errstr ->
  foldM (inner errstr) (Right tc) kv
  where
    inner _ (Left err) _ = return (Left err)
    inner errstr (Right cnf) (k,v) = do
      res <- setTopicConfKV cnf k v errstr
      case res of
        conf_res_ok -> return $ Right cnf
        otherwise -> Left <$> peekCStringLen errstr


dupTopicConf :: RdKafkaTopicConf -> IO RdKafkaTopicConf
dupTopicConf tc = wrapTopicConfPtr =<< withForeignPtr tc c_rd_kafka_topic_conf_dup

newTopicConfInternal :: IO RdKafkaTopicConf
newTopicConfInternal = wrapTopicConfPtr =<< c_rd_kafka_topic_conf_new

newTopicConf :: [(String, String)] -> Either String RdKafkaTopicConf
newTopicConf kv = unsafePerformIO $ (setTopicConfMult kv) =<< newTopicConfInternal

assocTopicConf :: RdKafkaTopicConf -> [(String, String)] -> Either String RdKafkaTopicConf
assocTopicConf otc kv = unsafePerformIO $ (setTopicConfMult kv) =<< dupTopicConf otc