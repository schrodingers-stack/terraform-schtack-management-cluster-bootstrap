data "github_repository_file" "chart_definition" {
  repository = var.repository
  branch     = var.target_revision
  file       = "Chart.yaml"
}

data "github_repository_file" "values_common" {
  repository = var.repository
  branch     = var.target_revision
  file       = "values-common.yaml"
}

data "github_repository_file" "values_bootstrap" {
  repository = var.repository
  branch     = var.target_revision
  file       = "values-bootstrap.yaml"
}

data "utils_deep_merge_yaml" "values" {
  input = [
    data.github_repository_file.values_common.content,
    data.github_repository_file.values_bootstrap.content,
  ]
  append_list = true
}

# TODO Maybe variabilize the release name and namespace? This will require that all other resources that depend on this resource also have the same variables.
resource "helm_release" "argo_cd_bootstrap" {
  name = "argo-cd"

  repository = yamldecode(data.github_repository_file.chart_definition.content).dependencies[0].repository
  chart      = yamldecode(data.github_repository_file.chart_definition.content).dependencies[0].name
  version    = yamldecode(data.github_repository_file.chart_definition.content).dependencies[0].version

  namespace        = "argo-cd"
  create_namespace = true
  # FIXME Find a better way to get only the values inside the `argo-cd` key.
  values = [yamlencode(yamldecode(data.utils_deep_merge_yaml.values.output).argo-cd)]

  lifecycle {
    # Ignore all changes after the bootstrap, since the Argo CD application will manage itself later on.
    ignore_changes = all
  }
}
