:ok = LocalCluster.start()

Application.ensure_all_started(:caravan)

ExUnit.start()
