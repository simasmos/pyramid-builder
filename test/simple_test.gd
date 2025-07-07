extends "res://addons/gut/test.gd"

# Simple test to verify GUT framework is working
func test_basic_assertions():
	assert_eq(2 + 2, 4)
	assert_true(true)
	assert_false(false)
	assert_not_null("hello")

func test_string_operations():
	var text = "Hello World"
	assert_eq(text.length(), 11)
	assert_true(text.begins_with("Hello"))

func test_array_operations():
	var arr = [1, 2, 3]
	assert_eq(arr.size(), 3)
	assert_true(arr.has(2))
	assert_false(arr.has(5))

func test_vector_operations():
	var vec = Vector2i(5, 10)
	assert_eq(vec.x, 5)
	assert_eq(vec.y, 10)