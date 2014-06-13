{-# LANGUAGE CPP, ForeignFunctionInterface #-}

module Database.Kafka.RdKafka.Message (
  RdKafkaMessage(..),
  freeMessage,
  checkError
) where

import Foreign hiding (unsafePerformIO)
import Foreign.C.Types
import Foreign.C.String
import System.IO.Unsafe (unsafePerformIO)
import qualified Data.ByteString as BS

import Database.Kafka.RdKafka.Errors (RdKafkaError)
import Database.Kafka.RdKafka.Topic (RdKafkaTopic)

#include <librdkafka/rdkafka.h>

-----------
-- Messages
-----------

newtype ArbitraryRegion
type ArbitraryPtr = Ptr ArbitraryRegion
type Size = CInt

data RdKafkaMessage = RdKafkaMessage {
  err :: RdKafkaError,
  topic :: RdKafkaTopicPtr,
  partition :: CInt,
  payload :: ArbitraryPtr,
  len :: CSize,
  key :: ArbitraryPtr,
  keyLen :: CSize,
  offset :: CLong,
  private :: ArbitraryPtr
}

foreign import ccall unsafe "rdkafka.h &rd_kafka_message_destroy"
  c_rd_kafka_message_destroy :: FunPtr (Ptr RdKafkaMessage -> IO ())

foreign import ccall unsafe "rdkafka.h rd_kafka_message_errstr"
  c_rd_kafka_message_errstr :: ForeignPtr RdKafkaMessage -> CString

foreignMessage :: Ptr RdKafkaMessage -> IO (ForeignPtr RdKafkaMessage)
foreignMessage = newForeignPtr c_rd_kafka_message_destroy

parseMessage :: ForeignPtr RdKafkaMessage -> Either String Message
parseMessage m = unsafePerformIO $ \ -> do
    let cerrstr = c_rd_kafka_message_errstr m
    if cerrstr == nullPtr then
      return Right =<< peekMessage m
    else
      return Left =<< peekCString cerrstr

--peekMessage :: ForeignPtr RdKafkaMessage -> IO Message
--peekMessage pm = do
--  m <- peek pm

