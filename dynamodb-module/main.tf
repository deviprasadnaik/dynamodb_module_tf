resource "aws_dynamodb_table" "this" {
  count = var.create_table ? 1 : 0

  name                        = var.data.name
  billing_mode                = var.billing_mode
  hash_key                    = var.data.hash_key
  range_key                   = var.data.range_key
  read_capacity               = var.read_capacity
  write_capacity              = var.write_capacity
  stream_enabled              = var.stream_enabled
  stream_view_type            = var.stream_view_type
  table_class                 = var.data.table_class
  deletion_protection_enabled = var.data.deletion_protection_enabled

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  dynamic "attribute" {
    for_each = var.data.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.data.global_secondary_indexes

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
    for_each = var.data.replica_regions

    content {
      region_name            = replica.value.region_name
      kms_key_arn            = try(replica.value.kms_key_arn, null)
      propagate_tags         = try(replica.value.propagate_tags, false)
      point_in_time_recovery = try(replica.value.point_in_time_recovery, false)
    }
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_arn
  }


  dynamic "on_demand_throughput" {
    for_each = length(var.data.on_demand_throughput) > 0 ? [var.data.on_demand_throughput] : []

    content {
      max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
      max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.data.name
    }
  )

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }
}
