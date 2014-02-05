package disk

type PartitionType string

const (
	PartitionTypeSwap  PartitionType = "swap"
	PartitionTypeLinux               = "linux"
	PartitionTypeEmpty               = "empty"
)

type Partition struct {
	SizeInMb uint64
	Type     PartitionType
}

type Partitioner interface {
	Partition(devicePath string, partitions []Partition) (err error)
	GetDeviceSizeInMb(devicePath string) (size uint64, err error)
}
