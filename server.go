package gotime

import (
	"strconv"
	"time"
)

func Now() string {
	return strconv.FormatInt(time.Now().UnixNano(), 10)
}
