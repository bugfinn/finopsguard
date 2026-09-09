package main

required_tags := {"Project", "ManagedBy"}

taggable_types := {
	"aws_dynamodb_table",
	"aws_lambda_function",
	"aws_iam_role",
	"aws_sns_topic",
}

deny contains msg if {
	some resource_type, resources in input.resource
	taggable_types[resource_type]
	some resource_name, resource_bodies in resources
	some resource_body in resource_bodies
	tags := object.get(resource_body, "tags", {})
	tag_keys := {k | some k, _ in tags}
	missing := required_tags - tag_keys
	count(missing) > 0
	msg := sprintf("%s.%s is missing required tag(s): %v", [resource_type, resource_name, missing])
}
