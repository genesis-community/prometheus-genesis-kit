# Bug Fixes

* The kit validates that the nginx certificates are valid for the static IP only if an external domain is not explicitly given. In the case that one is, it will validate that the certificate is signed for that external domain.
