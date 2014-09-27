module Database.Kafka.Types (
  Message,
  Topic,
  Partition,
  Offset,
  Producer,
  Consumer,
  TopicConfig,
  ProducerConfig,
  ConsumerConfig,
  KafkaConfig
) where

newtype Partition = Partition { unPartition :: Int }
  deriving (Show, Eq)

newtype Offset = Offset { unOffset :: Int }
  deriving (Show, Eq, Ord, Num)

newtype Topic = Topic { unTopic :: String }
  deriving (Show, Eq, Ord)

data Message k v = Message {
  messageTopic :: Topic,
  messagePartition :: Partition,
  messageOffset :: Offset,
  messageKey :: k,
  messageValue :: v
} deriving (Show)

data Producer = Producer ()
data ProducerConfig = ProducerConfig ()
data ConsumerConfig = ConsumerConfig ()
data Consumer = Consumer ()



data TopicConfig = TopicConfig ()
data KafkaConfig = KafkaConfig ()