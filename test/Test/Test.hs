module Test.Test where

import Test.Framework (testGroup)
import Test.Framework.Providers.HUnit (testCase)
--import Test.Framework.Providers.QuickCheck2 (testProperty)

--import Test.QuickCheck (NonNegative(..), (==>))
import Test.HUnit (assertEqual)

import Database.Kafka.RdKafka.Interface

-----------------
-- Properties
-----------------


-----------------
-- Cases
-----------------

case_librdkafka_version = do
  assertEqual "for the version check" "0.8.3" version

case_librdkafka_errors = do
  assertEqual "for partition errors" "Local: Unknown partition" (errorToString error_unknown_partition)
  assertEqual "for message size errors" "Broker: Invalid message size" (errorToString error_invalid_msg_size)
  assertEqual "for no errors" "Success" (errorToString error_no_error)

tests = [
   testGroup "librdkafka basics" [
     testCase "version" case_librdkafka_version
    ,testCase "errors" case_librdkafka_errors
    ]
  ]