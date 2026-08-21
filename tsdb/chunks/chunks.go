// Copyright The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


// The slim fork retains only the pure declarations of upstream
// tsdb/chunks: the reference and meta types, the test-sample helpers,
// and the iterator interface consumed by storage/interface.go. The
// on-disk segment writer and reader moved out with the local TSDB.

package chunks

import (
	"errors"
	"fmt"

	"github.com/prometheus/prometheus/tsdb/chunkenc"
)

// ChunkRef is a generic reference for reading chunk data. In prometheus it
// is either a HeadChunkRef or BlockChunkRef, though other implementations
// may have their own reference types.
type ChunkRef uint64

type Meta struct {
	// Ref and Chunk hold either a reference that can be used to retrieve
	// chunk data or the data itself.
	// If Chunk is nil, call ChunkReader.ChunkOrIterable(Meta.Ref) to get the
	// chunk and assign it to the Chunk field. If an iterable is returned from
	// that method, then it may not be possible to set Chunk as the iterable
	// might form several chunks.
	Ref   ChunkRef
	Chunk chunkenc.Chunk

	// Time range the data covers.
	// When MaxTime == math.MaxInt64 the chunk is still open and being appended to.
	MinTime, MaxTime int64
}

// ChunkFromSamples requires all samples to have the same type.
// It is not efficient and meant for testing purposes only.
// It scans the samples to determine whether any sample has ST set and
// creates a chunk accordingly.
func ChunkFromSamples(s []Sample) (Meta, error) {
	return ChunkFromSamplesGeneric(SampleSlice(s))
}

// ChunkFromSamplesGeneric requires all samples to have the same type.
func ChunkFromSamplesGeneric(s Samples) (Meta, error) {
	emptyChunk := Meta{Chunk: chunkenc.NewXORChunk()}
	mint, maxt := int64(0), int64(0)

	if s.Len() > 0 {
		mint, maxt = s.Get(0).T(), s.Get(s.Len()-1).T()
	}

	if s.Len() == 0 {
		return emptyChunk, nil
	}

	sampleType := s.Get(0).Type()

	hasST := false
	for i := range s.Len() {
		if s.Get(i).ST() != 0 {
			hasST = true
			break
		}
	}

	// Request storing ST in the chunk if available.
	c, err := sampleType.NewChunk(hasST, hasST)
	if err != nil {
		return Meta{}, err
	}

	ca, _ := c.Appender()
	var newChunk chunkenc.Chunk

	for i := 0; i < s.Len(); i++ {
		switch sampleType {
		case chunkenc.ValFloat:
			ca.Append(s.Get(i).ST(), s.Get(i).T(), s.Get(i).F())
		case chunkenc.ValHistogram:
			newChunk, _, ca, err = ca.AppendHistogram(nil, s.Get(i).ST(), s.Get(i).T(), s.Get(i).H(), false)
			if err != nil {
				return emptyChunk, err
			}
			if newChunk != nil {
				return emptyChunk, errors.New("did not expect to start a second chunk")
			}
		case chunkenc.ValFloatHistogram:
			newChunk, _, ca, err = ca.AppendFloatHistogram(nil, s.Get(i).ST(), s.Get(i).T(), s.Get(i).FH(), false)
			if err != nil {
				return emptyChunk, err
			}
			if newChunk != nil {
				return emptyChunk, errors.New("did not expect to start a second chunk")
			}
		default:
			panic(fmt.Sprintf("unknown sample type %s", sampleType.String()))
		}
	}
	return Meta{
		MinTime: mint,
		MaxTime: maxt,
		Chunk:   c,
	}, nil
}

// ChunkMetasToSamples converts a slice of chunk meta data to a slice of samples.
// Used in tests to compare the content of chunks.
func ChunkMetasToSamples(chunks []Meta) (result []Sample) {
	if len(chunks) == 0 {
		return result
	}

	for _, chunk := range chunks {
		it := chunk.Chunk.Iterator(nil)
		for vt := it.Next(); vt != chunkenc.ValNone; vt = it.Next() {
			switch vt {
			case chunkenc.ValFloat:
				t, v := it.At()
				result = append(result, sample{t: t, f: v})
			case chunkenc.ValHistogram:
				t, h := it.AtHistogram(nil)
				result = append(result, sample{t: t, h: h})
			case chunkenc.ValFloatHistogram:
				t, fh := it.AtFloatHistogram(nil)
				result = append(result, sample{t: t, fh: fh})
			default:
				panic("unexpected value type")
			}
		}
	}
	return result
}

// Iterator iterates over the chunks of a single time series.
type Iterator interface {
	// At returns the current meta.
	// It depends on the implementation whether the chunk is populated or not.
	At() Meta
	// Next advances the iterator by one.
	Next() bool
	// Err returns optional error if Next is false.
	Err() error
}
