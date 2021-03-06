FROM debian:jessie 
COPY . .    
RUN apt-get update && apt-get install -y python-pip python2.7-dev libxml2 libxml2-dev libxslt1-dev curl libffi-dev git libpq-dev  
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs default-jdk 
RUN pip install -r requirements.txt 
RUN which npm    
RUN /usr/bin/npm install 
RUN /usr/bin/npm install -g bower grunt coffee-script 
RUN /usr/bin/bower install --allow-root  
RUN /usr/bin/grunt build    
ADD surveys.json / 
RUN python manage.py syncdb --noinput
RUN ./docker/create_demo_user.sh
RUN python manage.py migrate
RUN python manage.py loaddata /surveys.json
ENV DEFAULT_KOBO_USER admin 
ENV DEFAULT_KOBO_PASS pass 
CMD /usr/bin/python manage.py gruntserver 0.0.0.0:8000 
EXPOSE 8000