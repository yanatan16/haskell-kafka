{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Topic (
  RdKafkaTopicConf,
  newTopicConf,
  assocTopicConf
) where

import Foreignn hiding (unsafePerformIO)
import Foreign.C.Types (CInt, CSize)
import Foreign.C.String (CString, withCString, withCStringLen)
import Foreign.Ptr (Ptr)
import System.IO.Unsafe (unsafePerformIO)

import Database.Kafka.RdKafka.Conf (RdKafkaConfResponse, conf_res_ok)

#include <librdkafka/rdkafka.h>

newtype RdKafkaTopicConfBase
type RdKafkaTopicConf = ForeignPtr RdKafkaTopicConfBase

foreign import ccall unsafe "rdkafka.h &rd_kafka_topic_conf_destroy"
  c_rd_kafka_topic_conf_destroy :: FunPtr (Ptr RdKafkaTopicConfBase -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_new"
  c_rd_kafka_topic_conf_new :: IO (Ptr RdKafkaTopicConfBase)

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_dup"
  c_rd_kafka_topic_conf_dup :: RdKafkaTopicConf -> IO (Ptr RdKafkaTopicConfBase)

foreign import ccall unsafe "rdkafka.h rd_kafka_topic_conf_set"
  c_rd_kafka_topic_conf_set :: RdKafkaTopicConf
                            -> CString
                            -> CString
                            -> CString
                            -> CSize
                            -> IO RdKafkaConfResponse

wrapTopicConfPtr :: Ptr RdKafkaTopicConfBase -> RdKafkaTopicConf
wrapTopicConfPtr = newForeignPtr c_rd_kafka_topic_conf_destroy

setTopicConfKV :: RdKafkaTopicConf -> String -> String -> IO RdKafkaConfResponse
setTopicConfKV ptr k v = withCStringLen "" $ \errstr -> do
  let errlen = fromIntegral $ snd errstr
  let errcstr = fst errstr
  withCString k $ \ck -> do
    withCString v $ \cv -> do
      c_rd_kafka_topic_conf_set ptr ck cv errcstr errlen

setTopicConfMult :: Map String String -> RdKafkaTopicConf -> IO (Either String RdKafkaTopicConf)
setTopicConfMult kv tc = foldM inner (Right ())
  where
    inner (Left err) _ = return (Left err)
    inner (Right _) (k,v) = do
      res <- setTopicConfKV tc k v
      return $ case res of
        conf_res_ok -> Right ()
        otherwise -> Left (show res)

dupTopicConf :: RdKafkaTopicConf -> IO RdKafkaTopicConf
dupTopicConf tc = wrapTopicConfPtr <$> c_rd_kafka_topic_conf_dup tc

newTopicConfInternal :: IO RdKafkaPtr
newTopicConfInternal = wrapTopicConfPtr <$> c_rd_kafka_topic_conf_new

newTopicConf :: Map String String -> Either String RdKafkaTopicConf
newTopicConf kv = unsafePerformIO $ (setTopicConfMult kv) =<< newTopicConfInternal

assocTopicConf :: RdKafkaTopicConf -> Map String String -> Either String RdKafkaTopicConf
assocTopicConf otc kv = unsafePerformIO $ (setTopicConfMult kv) =<< dupTopicConf otc