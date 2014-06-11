module Test.Test where

import Test.Framework (testGroup)
import Test.Framework.Providers.HUnit (testCase)
--import Test.Framework.Providers.QuickCheck2 (testProperty)

--import Test.QuickCheck (NonNegative(..), (==>))
import Test.HUnit (assertEqual)

import Database.Kafka.RdKafka.C

-----------------
-- Properties
-----------------


-----------------
-- Cases
-----------------

case_librdkafka_version = do
  assertEqual "for the version check" "0.8.3" version

tests = [
   testGroup "librdkafka" [
     testCase "Version" case_librdkafka_version
    ]
  ]