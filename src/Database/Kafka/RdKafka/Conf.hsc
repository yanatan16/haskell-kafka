{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Conf (
  RdKafkaConfResponse(..),
  conf_res_unknown, conf_res_invalid, conf_res_ok,

  RdKafkaConf, RdKafkaConfRaw,
  newConf, assocConf
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)

import Control.Monad (foldM)
import Control.Applicative ((<$>), (<*>))

import Database.Kafka.RdKafka.Errors (withErrorBuffer)

#include <librdkafka/rdkafka.h>

-- Response

newtype RdKafkaConfResponse = RdKafkaConfResponse CInt
#{enum RdKafkaConfResponse, RdKafkaConfResponse
, conf_res_unknown = RD_KAFKA_CONF_UNKNOWN
, conf_res_invalid = RD_KAFKA_CONF_INVALID
, conf_res_ok = RD_KAFKA_CONF_OK}

instance Show RdKafkaConfResponse where
  show conf_res_unknown = "Unknown Configuration Key"
  show conf_res_invalid = "Invalid Configuration Value"
  show conf_res_ok = "OK"

-- Actual Conf Type

data RdKafkaConfBase
type RdKafkaConfRaw = Ptr RdKafkaConfBase
type RdKafkaConf = ForeignPtr RdKafkaConfBase

foreign import ccall unsafe "rdkafka.h &rd_kafka_conf_destroy"
  c_rd_kafka_conf_destroy :: FunPtr (RdKafkaConfRaw -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_conf_new"
  c_rd_kafka_conf_new :: IO RdKafkaConfRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_conf_dup"
  c_rd_kafka_conf_dup :: RdKafkaConfRaw -> IO RdKafkaConfRaw

foreign import ccall unsafe "rdkafka.h rd_kafka_conf_set"
  c_rd_kafka_conf_set :: RdKafkaConfRaw
                         -> CString
                         -> CString
                         -> CString
                         -> CSize
                         -> IO RdKafkaConfResponse

wrapConfPtr :: RdKafkaConfRaw -> IO RdKafkaConf
wrapConfPtr = newForeignPtr c_rd_kafka_conf_destroy

setConfKV :: RdKafkaConf -> String -> String -> CStringLen -> IO RdKafkaConfResponse
setConfKV conf k v (errstr, errlen) = do
  withCString k $ \ck ->
    withCString v $ \cv ->
      withForeignPtr conf $ \confraw ->
        c_rd_kafka_conf_set confraw ck cv errstr (fromIntegral errlen)

setConfMult :: [(String, String)] -> RdKafkaConf -> IO (Either String RdKafkaConf)
setConfMult kv conf = withErrorBuffer $ \errstr ->
    foldM (inner errstr) (Right conf) kv
  where
    inner _ (Left err) _ = return (Left err)
    inner errstr (Right cnf) (k,v) = do
      res <- setConfKV cnf k v errstr
      case res of
        conf_res_ok -> return $ Right cnf
        otherwise   -> Left <$> peekCStringLen errstr


dupConf :: RdKafkaConf -> IO RdKafkaConf
dupConf tc = wrapConfPtr =<< withForeignPtr tc c_rd_kafka_conf_dup

newConfInternal :: IO RdKafkaConf
newConfInternal = wrapConfPtr =<< c_rd_kafka_conf_new

newConf :: [(String, String)] -> Either String RdKafkaConf
newConf kv = unsafePerformIO $ (setConfMult kv) =<< newConfInternal

assocConf :: RdKafkaConf -> [(String, String)] -> Either String RdKafkaConf
assocConf otc kv = unsafePerformIO $ (setConfMult kv) =<< dupConf otc