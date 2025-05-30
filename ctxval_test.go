package ctxval_test

import (
	"context" // Import the current package
	"testing"

	"github.com/kluzzebass/ctxval"
)

type testStruct struct {
	Value string
}

type testInterface interface {
	DoSomething()
}

type testImpl struct{}

func (t testImpl) DoSomething() {}

func TestSet(t *testing.T) {
	ctx := context.Background()

	// Test setting a basic type
	ctx = ctxval.Set(ctx, "test")
	val, ok := ctxval.Get[string](ctx)
	if !ok || val != "test" {
		t.Error("failed to get string value")
	}

	// Test setting a struct
	ts := testStruct{Value: "test"}
	ctx = ctxval.Set(ctx, ts)
	val2, ok := ctxval.Get[testStruct](ctx)
	if !ok || val2.Value != "test" {
		t.Error("failed to get struct value")
	}

	// Test setting a pointer
	ptr := &testStruct{Value: "test"}
	ctx = ctxval.Set(ctx, ptr)
	val3, ok := ctxval.Get[*testStruct](ctx)
	if !ok || val3.Value != "test" {
		t.Error("failed to get pointer value")
	}

	// Test setting nil pointer
	var nilPtr *testStruct
	ctx = ctxval.Set(ctx, nilPtr)
	val4, ok := ctxval.Get[*testStruct](ctx)
	if !ok || val4 != nil {
		t.Error("failed to get nil pointer value")
	}

	// Test setting interface
	var ti testInterface = testImpl{}
	ctx = ctxval.Set(ctx, ti)
	val5, ok := ctxval.Get[testInterface](ctx)
	if !ok || val5 == nil {
		t.Error("failed to get interface value")
	}

	// Test setting nil interface
	ctx = ctxval.Set[testInterface](ctx, nil)
	val6, ok := ctxval.Get[testInterface](ctx)
	if ok || val6 != nil {
		t.Error("should not get nil interface value")
	}
}

func TestGet(t *testing.T) {
	ctx := context.Background()

	// Test getting non-existent value
	val, ok := ctxval.Get[string](ctx)
	if ok || val != "" {
		t.Error("should not get non-existent value")
	}

	// Test getting wrong type
	ctx = ctxval.Set(ctx, "test")
	val2, ok := ctxval.Get[int](ctx)
	if ok || val2 != 0 {
		t.Error("should not get value of wrong type")
	}
}

func TestMustGet(t *testing.T) {
	ctx := context.Background()

	// Test MustGet with existing value
	ctx = ctxval.Set(ctx, "test")
	val := ctxval.MustGet[string](ctx)
	if val != "test" {
		t.Error("failed to must get value")
	}

	// Test MustGet with interface type
	var i testInterface = testImpl{}
	ctx = ctxval.Set(ctx, i)
	val2 := ctxval.MustGet[testInterface](ctx)
	if val2 == nil {
		t.Error("failed to must get interface value")
	}

	// Test MustGet panics with non-existent value
	defer func() {
		if r := recover(); r == nil {
			t.Error("MustGet should panic on non-existent value")
		}
	}()
	_ = ctxval.MustGet[int](ctx)
}

func TestMustGetWithNilInterface(t *testing.T) {
	ctx := context.Background()

	ctx = ctxval.Set[testInterface](ctx, nil)

	// Test MustGet panics with nil interface
	defer func() {
		if r := recover(); r == nil {
			t.Error("MustGet should panic on nil interface value")
		}
	}()

	_ = ctxval.MustGet[testInterface](ctx)
}
