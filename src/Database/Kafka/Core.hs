module Database.Kafka.Core (
  connectProducer,
  connectConsumer,
  push,
  pull
) where

import Database.Kafka.Types (KafkaConfig, ProducerConfig, ConsumerConfig, TopicConfig, Consumer, Producer, Message)

connectProducer :: KafkaConfig -> ProducerConfig -> TopicConfig -> IO (Either String Producer)
connectProducer = error "Not Implemented"

connectConsumer :: KafkaConfig -> ConsumerConfig -> TopicConfig -> IO (Either String Consumer)
connectConsumer = error "Not Implemented"

push :: Producer -> Message k v -> IO (Either String ())
push = error "Not Implemented"

pull :: Consumer -> IO (Either String (Message k v))
pull = error "Not Implemented"

