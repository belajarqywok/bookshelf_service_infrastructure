local_registry:
	docker run -d -p 5000:5000 \
		--restart=always \
		--name registry registry:2


postgres_cluster:
	kubectl create ns postgres_cluster

	kubectl apply -f postgres-cluster/postgres_pv_pvc.yaml

	export POSTGRES_DB = bookshelf
	export POSTGRES_USER = postgres
	export POSTGRES_PASSWORD = postgre-akdiuwd92udniudh92uedn
	envsubst < postgres-cluster/postgres_config.yaml | \
		kubectl apply -n postgres_cluster -f -

	kubectl apply -n postgres_cluster \
		-f postgres-cluster/postgres_deployment.yaml

	kubectl apply -n postgres_cluster \
		-f postgres-cluster/postgres_service.yaml

	minikube service postgres_service \
		-n postgres_cluster


redis_cluster:
	kubectl create ns redis_cluster

	kubectl apply -f redis-cluster/redis_storage_class.yaml
	kubectl apply -f redis-cluster/redis_persistent_volume.yaml

	export REDIS_PASSWORD = redis-akdiuwd92udniudh92uedn
	envsubst < redis-cluster/redis_config.yaml | \
		kubectl apply -n redis_cluster -f -

	kubectl apply -n redis_cluster \
		-f redis-cluster/redis_statefulset.yaml

	kubectl apply -n redis_cluster \
		-f redis-cluster/redis_service.yaml

	minikube service redis_service \
		-n redis_cluster


bookshelf_cluster:
	kubectl create ns bookshelf_cluster

	export SRV_HOST = 0.0.0.0
	export SRV_PORT = 3000

	export MAX_LIMIT_REQ = 100
	export TIME_LIMIT_REQ = 60
	
	export SECRET_KEY = app-key-akdiuwd92udniudh92uedn
	export ACCESS_TOKEN_EXPIRATION = 1
	export REFRESH_TOKEN_EXPIRATION = 3
	export JWT_ALGORITHM = HS512

	export DATABASE_URL=postgresql://postgres:postgre-akdiuwd92udniudh92uedn@192.168.49.2:33002/bookshelf&connection_limit=100&connect_timeout=120&pool_timeout=120

	export REDIS_HOST = 192.168.49.2
	export REDIS_PORT = 33002
	export REDIS_PASSWORD = redis-akdiuwd92udniudh92uedn
	envsubst < bookshelf-cluster/bookshelf_deployment.yaml | \
		kubectl apply -n bookshelf_cluster -f -

	kubectl apply -n bookshelf_cluster \
		-f bookshelf-cluster/bookshelf_service.yaml

	kubectl apply -n bookshelf_cluster \
		-f bookshelf-cluster/bookshelf_hpa.yaml

	num_services=5
	for ((service=1; service<=$num_services; service++))
	do
		service_name="bookshelf_service-$service"
		minikube service $service_name -n bookshelf_cluster
	done


nginx_cluster:
	kubectl create ns nginx_cluster

	kubectl apply -n nginx_cluster \
		-f nginx-cluster/nginx_config.yaml

	kubectl apply -n nginx_cluster \
		-f nginx-cluster/nginx_deployment.yaml

	kubectl apply -n nginx_cluster \
		-f nginx-cluster/nginx_service.yaml

	kubectl apply -n nginx_cluster \
		-f nginx-cluster/nginx_hpa.yaml

	minikube service nginx_service \
		-n nginx_cluster