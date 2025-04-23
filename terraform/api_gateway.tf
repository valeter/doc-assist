resource "yandex_api_gateway" "static-gateway" {
  count = var.doc_assist_version == null ? 0 : 1
  
  folder_id   = local.network_folder_id
  name        = "static-gateway"
  description = "gateway for doc assist bot"
  spec        = <<-EOT
openapi: "3.0.0"
info:
  version: 1.0.0
  title: doc-assist bot API
paths:
  /ping:
    get:
      x-yc-apigateway-integration:
        type: dummy
        http_code: 200
        content:
          "text/plain": "pong"
  /${yandex_function.doc-assist[0].name}:
    post:
      x-yc-apigateway-integration:
        type: cloud_functions
        function_id: ${yandex_function.doc-assist[0].id}
        service_account_id: ${yandex_iam_service_account.func-sa.id}
        tag: "$latest"
        timeout: 30
      operationId: ${yandex_function.doc-assist[0].name}
      responses:
        '200':
          description: Success
        '502':
          description: Bad Gateway
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                    description: Error message
EOT
  connectivity {
    network_id = yandex_vpc_network.default-network.id
  }
  log_options {
    log_group_id = yandex_logging_group.static-gateway-log.id
    min_level = "INFO"
  }
  execution_timeout = "30"
  depends_on = [ yandex_function.doc-assist[0] ]
}