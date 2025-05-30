// Package ctxval provides generic helpers for storing and retrieving typed values
// from a context.Context. It aims to reduce boilerplate when managing multiple
// distinct types within a context.
package ctxval

import (
	"context"
	"fmt"
	"reflect" // Used for MustGet's panic message
)

// typeKey is an unexported struct type.
// When used with a type parameter T (e.g., typeKey[MyType]),
// it effectively creates a unique type for each MyType.
// The zero value of this unique type (e.g., typeKey[MyType]{})
// is then used as a context key. This ensures that keys for different
// types (e.g., typeKey[User] and typeKey[Logger]) are distinct and do not collide.
type typeKey[T any] struct{}

// Set stores a value of type T into the context, returning a new context.
// It uses a key derived from the type T itself, ensuring type-safe storage
// and retrieval. If a value of the same type T is already in the context
// using this mechanism, it will be overwritten.
func Set[T any](ctx context.Context, val T) context.Context {
	return context.WithValue(ctx, typeKey[T]{}, val)
}

// Get retrieves a value of type T from the context.
// It returns the value and a boolean `ok`.
//   - If a value of type T was found, it returns (value, true).
//     This includes cases where a typed nil was stored (e.g., `Set(ctx, (*User)(nil))`).
//   - If no value for type T is found, or if the stored value is not assignable
//     to T (which shouldn't happen if only `Set` from this package is used
//     for this type), it returns (zero value of T, false).
//
// Note on storing nil interfaces:
// If you call `Set[MyInterface](ctx, nil)` where `nil` is an untyped nil interface value,
// `context.WithValue` stores it in a way that `ctx.Value()` for that key returns `nil`.
// Consequently, `Get[MyInterface](ctx)` will return `(nil, false)` in this specific scenario,
// as it interprets the `nil` returned by `ctx.Value()` as "key not found".
// For typed nils (e.g., `var u *User; Set(ctx, u)` where `u` is `nil`), `Get` will correctly
// return `(nil, true)`.
func Get[T any](ctx context.Context) (T, bool) {
	val := ctx.Value(typeKey[T]{})
	if val == nil {
		var zero T
		return zero, false
	}

	typedVal, ok := val.(T)
	return typedVal, ok
}

// MustGet retrieves a value of type T from the context.
// It panics if the value is not found or if the type assertion fails (which
// implies the value was not stored using Set[T] or was overwritten by
// a different type using the same key, an unlikely scenario with typeKey[T]).
// This function is useful when the presence of the value is considered
// a critical precondition.
// MustGet (alternative for more specific interface type name in panic)
func MustGet[T any](ctx context.Context) T {
	val, ok := Get[T](ctx)
	if !ok {
		// Get the string representation of type T.
		// reflect.TypeOf((*T)(nil)) gives the reflect.Type of a pointer to T.
		// .Elem() dereferences this pointer type to get the reflect.Type of T.
		typeName := reflect.TypeOf((*T)(nil)).Elem().String()
		panic(
			fmt.Sprintf(
				"ctxval: value of type %s not found in context",
				typeName,
			),
		)
	}
	return val
}
