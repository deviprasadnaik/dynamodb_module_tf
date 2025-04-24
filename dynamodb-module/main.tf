resource "aws_dynamodb_table" "this" {
  count = var.data.create_table ? 1 : 0

  name                        = var.data.name
  billing_mode                = var.data.billing_mode
  hash_key                    = var.data.hash_key
  range_key                   = var.data.range_key
  read_capacity               = var.data.read_capacity
  write_capacity              = var.data.write_capacity
  stream_enabled              = var.data.stream_enabled
  stream_view_type            = var.data.stream_view_type
  table_class                 = var.data.table_class
  deletion_protection_enabled = var.data.deletion_protection_enabled

  dynamic "ttl" {
    for_each = try(var.data.ttl, null) != null ? [var.data.ttl] : []

    content {
      enabled        = true
      attribute_name = ttl.value.attribute_name
    }
  }

  point_in_time_recovery {
    enabled = var.data.point_in_time_recovery_enabled
  }

  dynamic "attribute" {
    for_each = var.data.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "local_secondary_index" {
    for_each = try(var.data.local_secondary_indexes, [])
    content {
      name               = local_secondary_index.value.name
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
      projection_type    = local_secondary_index.value.projection_type
      range_key          = local_secondary_index.value.range_key
    }
  }

  dynamic "global_secondary_index" {
    for_each = try(var.data.global_secondary_indexes, [])

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      projection_type    = global_secondary_index.value.projection_type
      range_key          = try(global_secondary_index.value.range_key, null)
      read_capacity      = try(global_secondary_index.value.read_capacity, null)
      write_capacity     = try(global_secondary_index.value.write_capacity, null)
      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? global_secondary_index.value.non_key_attributes : null
    }
  }

  dynamic "replica" {
    for_each = try(var.data.replica_regions, [])

    content {
      region_name            = replica.value.region_name
      kms_key_arn            = try(replica.value.kms_key_arn, null)
      propagate_tags         = try(replica.value.propagate_tags, false)
      point_in_time_recovery = try(replica.value.point_in_time_recovery, false)
    }
  }

  dynamic "server_side_encryption" {
    for_each = try(var.data.server_side_encryption, null) != null ? [var.data.server_side_encryption] : []

    content {
      enabled     = true
      kms_key_arn = aws_kms_key.this.arn
    }
  }

  dynamic "on_demand_throughput" {
    for_each = length(var.data.on_demand_throughput) > 0 ? [var.data.on_demand_throughput] : []

    content {
      max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
      max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
    }
  }

  tags = merge(
    var.data.tags,
    {
      "Name" = var.data.name,
      "backup" = true
    }
  )

  dynamic "timeouts" {
    for_each = try(var.data.timeouts, null) != null ? [var.data.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      update = timeouts.value.update
    }
  }

}

resource "aws_kms_key" "this" {
  description = "CMK for encrypting DynamoDB table"
  enable_key_rotation = true
}

resource "aws_dynamodb_contributor_insights" "this" {
  table_name = aws_dynamodb_table.this[0].name
}