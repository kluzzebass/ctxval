# ctxval

A generic way to inject into and retrieve values from a context

## Usage

The `ctxval` package provides a type-safe way to store and retrieve values in a context.Context.

### Basic Usage

The `ctxval` package allows you to store and retrieve values from a `context.Context` in a type-safe manner. It uses generic functions, so you specify the type at the call site.

**1. Storing and Retrieving Values with `Set` and `Get`**

Use `ctxval.Set[T](ctx, value)` to store a value of type `T` and `ctxval.Get[T](ctx)` to retrieve it. `Get` returns the value and a boolean indicating if the value was found.

```go
package main

import (
    "context"
    "fmt"
    "github.com/kluzzebass/ctxval"
)

type User struct {
    ID   int
    Name string
}

func main() {
    ctx := context.Background()

    // Store a User value
    user := User{ID: 1, Name: "Alice"}
    ctx = ctxval.Set[User](ctx, user)

    // Retrieve the User value
    retrievedUser, ok := ctxval.Get[User](ctx)
    if ok {
        fmt.Printf("Found user: %+v\n", retrievedUser)
    } else {
        fmt.Println("User not found")
    }

    // Try to get a value that doesn't exist
    _, ok = ctxval.Get[string](ctx)
    if !ok {
        fmt.Println("String value not found")
    }
}
```

**2. Using `MustGet` for Required Values**

When you know a value must be present in the context, use `MustGet[T](ctx)`. It returns the value directly but panics if the value is not found.

```go
func processUser(ctx context.Context) {
    // This will panic if no User was stored in the context
    user := ctxval.MustGet[User](ctx)
    fmt.Printf("Processing user: %s\n", user.Name)
}

func main() {
    ctx := context.Background()
    user := User{ID: 1, Name: "Bob"}
    ctx = ctxval.Set[User](ctx, user)

    processUser(ctx) // Works fine

    // This would panic:
    // processUser(context.Background())
}
```

**3. Type Safety**

Each type gets its own key space, so you can store multiple different types without conflicts:

```go
ctx := context.Background()

// Store different types
ctx = ctxval.Set[string](ctx, "hello")
ctx = ctxval.Set[int](ctx, 42)
ctx = ctxval.Set[User](ctx, User{ID: 1, Name: "Charlie"})

// Retrieve each type independently
str, _ := ctxval.Get[string](ctx)  // "hello"
num, _ := ctxval.Get[int](ctx)    // 42
user, _ := ctxval.Get[User](ctx)  // User{ID: 1, Name: "Charlie"}
```

**4. Working with Interfaces and Pointers**

The package works with any type, including interfaces and pointers:

```go
type Logger interface {
    Log(message string)
}

type ConsoleLogger struct{}
func (c ConsoleLogger) Log(message string) {
    fmt.Println("LOG:", message)
}

func main() {
    ctx := context.Background()

    // Store an interface
    var logger Logger = ConsoleLogger{}
    ctx = ctxval.Set[Logger](ctx, logger)

    // Store a pointer
    user := &User{ID: 1, Name: "Dave"}
    ctx = ctxval.Set[*User](ctx, user)

    // Retrieve them
    retrievedLogger, _ := ctxval.Get[Logger](ctx)
    retrievedUser, _ := ctxval.Get[*User](ctx)

    retrievedLogger.Log("Hello from context!")
    fmt.Printf("User: %+v\n", retrievedUser)
}
```

**5. Handling Nil Values**

The package correctly handles typed nil values:

```go
ctx := context.Background()

// Store a typed nil pointer
var user *User = nil
ctx = ctxval.Set[*User](ctx, user)

// This will return (nil, true) - the nil pointer was found
retrievedUser, ok := ctxval.Get[*User](ctx)
fmt.Printf("User: %v, Found: %v\n", retrievedUser, ok) // User: <nil>, Found: true

// However, storing an untyped nil interface behaves differently
// ctxval.Set[Logger](ctx, nil) would make Get[Logger] return (nil, false)
```

## Features

- **Type Safety**: Values are stored and retrieved using their exact types
- **No Key Collisions**: Different types automatically get different keys
- **Generic**: Works with any Go type including structs, interfaces, pointers, and primitives
- **Zero Dependencies**: Only uses the standard library
- **Context-Friendly**: Integrates seamlessly with existing context patterns

## Common Patterns

**Middleware Pattern**

```go
func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Authenticate user...
        user := authenticateUser(r)

        // Store user in context
        ctx := ctxval.Set[*User](r.Context(), user)

        // Continue with updated context
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

func handleProtected(w http.ResponseWriter, r *http.Request) {
    // Get the authenticated user
    user := ctxval.MustGet[*User](r.Context())

    fmt.Fprintf(w, "Hello, %s!", user.Name)
}
```
