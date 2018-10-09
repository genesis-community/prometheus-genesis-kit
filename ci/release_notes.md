# Improvements

We've added two new parameters to the `monitor-cf` feature, which are:
* `doppler_port` - The port that CF Doppler listens on. (defaut: `4443`)
* `doppler_url` - The URL to use to connect to CF Doppler (default is extracted
  from Genesis Exodus data, which is `doppler.` + your CF system domain)