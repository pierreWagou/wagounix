# { ... }: {

#   home.file.".config/pip/pip.conf".text = ''
#     [global]
#     index-url = https://pypi.org/simple

#     [install]
#     extra-index-url = 
#         https://i544489:${artifactory-token}@common.repositories.cloud.sap/artifactory/api/pypi/mlworkbench-pypi/simple
#   ''
# }