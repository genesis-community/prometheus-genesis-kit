# Features
* Bump Prometheus release to `21.1.1`
* Bump PostgreSQL release to `2.0.0`
* Bump cf-routing release to `0.173.0`
* Make blackbox as a subkit
* Removed BOSH subkit, BOSH Service Discovery is set by default now

# Bug Fixes
* Fix rabbitmq subkit spruce grab bug
* Fix cf subkit missing `(( append ))` bug

# Release Engineering
* Added CI, now the release cycle is taken care of by Concourse pipeline

# Upgrade notes
When you uprade from `0.1.*`* to `0.2.0`: 
* Remove `bosh` from the feature list since it is set by default
* If you are using blackbox to probe some endpoints such as cf, you need add `blackbox` to the subkit feature list

