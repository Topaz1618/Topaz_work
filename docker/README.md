docker的学习  
需求：用docker部署测试环境，跟线上环境相同:tomcat+nginx+mysql+redis   
方案一：每个应用一个容器（比较倾向这个）   
方案二：只起一个centos容器，在里面搭建应用   
遇到的问题：   
容器挂载只能docker run，一exit容器就关闭了，容器里的目录也没了，非我所欲也，喜欢用nsenter进入容器，exit不会关闭，友好~ 所以挂载有什么其他的方式不喽？
