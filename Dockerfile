FROM ruby:2.6

LABEL Name=ruby-optimization Version=0.0.1

WORKDIR /app
COPY . /app

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y g++ valgrind \
  massif-visualizer --no-install-recommends \
  && apt-get purge --auto-remove -y curl \
	&& rm -rf /var/lib/apt/lists/* \
  && rm -rf /src/*.deb

RUN gem install pry && gem install oj

RUN groupadd -r massif && useradd -r -g massif massif \
  && chown -R massif:massif /app

USER massif

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
