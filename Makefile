RELTMPDIR=/tmp/release.$(PGO_VERSION)
RELFILE=/tmp/postgres-operator.$(PGO_VERSION).tar.gz

#======= Safety checks =======
check-go-vars:
ifndef GOPATH
	$(error GOPATH is not set)
endif
ifndef GOBIN
	$(error GOBIN is not set)
endif

#======= Main functions =======
macpgo:	check-go-vars
	cd pgo && env GOOS=darwin GOARCH=amd64 go build pgo.go && mv pgo $(GOBIN)/pgo-mac
	env GOOS=darwin GOARCH=amd64 go build github.com/blang/expenv && mv expenv $(GOBIN)/expenv-mac
winpgo:	check-go-vars
	cd pgo && env GOOS=windows GOARCH=386 go build pgo.go && mv pgo.exe $(GOBIN)/pgo.exe
	env GOOS=windows GOARCH=386 go build github.com/blang/expenv && mv expenv.exe $(GOBIN)/expenv.exe


gendeps: 
	godep save \
	github.com/crunchydata/postgres-operator/apis/cr/v1 \
	github.com/crunchydata/postgres-operator/util \
	github.com/crunchydata/postgres-operator/operator \
	github.com/crunchydata/postgres-operator/operator/backup \
	github.com/crunchydata/postgres-operator/operator/cluster \
	github.com/crunchydata/postgres-operator/operator/pvc \
	github.com/crunchydata/postgres-operator/controller \
	github.com/crunchydata/postgres-operator/client \
	github.com/crunchydata/postgres-operator/pgo/cmd \
	github.com/crunchydata/postgres-operator/apiservermsgs \
	github.com/crunchydata/postgres-operator/apiserver \
	github.com/crunchydata/postgres-operator/apiserver/backupservice \
	github.com/crunchydata/postgres-operator/apiserver/cloneservice \
	github.com/crunchydata/postgres-operator/apiserver/clusterservice \
	github.com/crunchydata/postgres-operator/apiserver/labelservice \
	github.com/crunchydata/postgres-operator/apiserver/loadservice \
	github.com/crunchydata/postgres-operator/apiserver/policyservice \
	github.com/crunchydata/postgres-operator/apiserver/pvcservice \
	github.com/crunchydata/postgres-operator/apiserver/upgradeservice \
	github.com/crunchydata/postgres-operator/apiserver/userservice \
	github.com/crunchydata/postgres-operator/apiserver/util \
	github.com/crunchydata/postgres-operator/apiserver/versionservice 
installrbac:
	cd deploy && ./install-rbac.sh
setup:
	./bin/get-deps.sh
setupnamespaces:
	cd deploy && ./setupnamespaces.sh
cleannamespaces:
	cd deploy && ./cleannamespaces.sh
bounce:
	$(PGO_CMD) --namespace=$(PGO_OPERATOR_NAMESPACE) get pod --selector=name=postgres-operator -o=jsonpath="{.items[0].metadata.name}" | xargs $(PGO_CMD) --namespace=$(PGO_OPERATOR_NAMESPACE) delete pod
deployoperator:
	cd deploy && ./deploy.sh
main:	check-go-vars
	go install postgres-operator.go
runmain:	check-go-vars
	postgres-operator --kubeconfig=/etc/kubernetes/admin.conf
runapiserver:	check-go-vars
	apiserver --kubeconfig=/etc/kubernetes/admin.conf
pgo-apiserver:	check-go-vars
	go install apiserver.go
pgo-backrest:	check-go-vars
	go install pgo-backrest/pgo-backrest.go
	mv $(GOBIN)/pgo-backrest ./bin/pgo-backrest/
pgo-backrest-image:	check-go-vars pgo-backrest
	docker build -t pgo-backrest -f $(PGO_BASEOS)/Dockerfile.pgo-backrest.$(PGO_BASEOS) .
	docker tag pgo-backrest $(PGO_IMAGE_PREFIX)/pgo-backrest:$(PGO_IMAGE_TAG)
pgo-backrest-restore-image:	check-go-vars 
	docker build -t pgo-backrest-restore -f $(PGO_BASEOS)/Dockerfile.pgo-backrest-restore.$(PGO_BASEOS) .
	docker tag pgo-backrest-restore $(PGO_IMAGE_PREFIX)/pgo-backrest-restore:$(PGO_IMAGE_TAG)
pgo-backrest-repo-image:	check-go-vars 
	docker build -t pgo-backrest-repo -f $(PGO_BASEOS)/Dockerfile.pgo-backrest-repo.$(PGO_BASEOS) .
	docker tag pgo-backrest-repo $(PGO_IMAGE_PREFIX)/pgo-backrest-repo:$(PGO_IMAGE_TAG)
cli-docs:	check-go-vars
	cd $(PGOROOT)/hugo/content/operatorcli/cli && go run $(PGOROOT)/pgo/generatedocs.go
pgo:	check-go-vars
	cd pgo && go install pgo.go
clean:	check-go-vars
	rm -rf $(GOPATH)/pkg/* $(GOBIN)/postgres-operator $(GOBIN)/apiserver $(GOBIN)/*pgo
pgo-apiserver-image:	check-go-vars
	go install apiserver.go
	cp $(GOBIN)/apiserver bin/
	docker build -t pgo-apiserver -f $(PGO_BASEOS)/Dockerfile.pgo-apiserver.$(PGO_BASEOS) .
	docker tag pgo-apiserver $(PGO_IMAGE_PREFIX)/pgo-apiserver:$(PGO_IMAGE_TAG)
#	docker push $(PGO_IMAGE_PREFIX)/pgo-apiserver:$(PGO_IMAGE_TAG)
postgres-operator:	check-go-vars
	go install postgres-operator.go
postgres-operator-image:	check-go-vars
	go install postgres-operator.go
	cp $(GOBIN)/postgres-operator bin/postgres-operator/
	docker build -t postgres-operator -f $(PGO_BASEOS)/Dockerfile.postgres-operator.$(PGO_BASEOS) .
	docker tag postgres-operator $(PGO_IMAGE_PREFIX)/postgres-operator:$(PGO_IMAGE_TAG)
#	docker push $(PGO_IMAGE_PREFIX)/postgres-operator:$(PGO_IMAGE_TAG)
deepsix:
	cd $(PGOROOT)/apis/cr/v1
	deepcopy-gen --go-header-file=$(PGOROOT)/apis/cr/v1/header.go.txt --input-dirs=.
pgo-lspvc-image:
	docker build -t pgo-lspvc -f $(PGO_BASEOS)/Dockerfile.pgo-lspvc.$(PGO_BASEOS) .
	docker tag pgo-lspvc $(PGO_IMAGE_PREFIX)/pgo-lspvc:$(PGO_IMAGE_TAG)
pgo-load-image:
	docker build -t pgo-load -f $(PGO_BASEOS)/Dockerfile.pgo-load.$(PGO_BASEOS) .
	docker tag pgo-load $(PGO_IMAGE_PREFIX)/pgo-load:$(PGO_IMAGE_TAG)
pgo-rmdata-image:
	docker build -t pgo-rmdata -f $(PGO_BASEOS)/Dockerfile.pgo-rmdata.$(PGO_BASEOS) .
	docker tag pgo-rmdata $(PGO_IMAGE_PREFIX)/pgo-rmdata:$(PGO_IMAGE_TAG)
pgo-sqlrunner-image:
	docker build -t pgo-sqlrunner -f $(PGO_BASEOS)/Dockerfile.pgo-sqlrunner.$(PGO_BASEOS) .
	docker tag pgo-sqlrunner $(PGO_IMAGE_PREFIX)/pgo-sqlrunner:$(PGO_IMAGE_TAG)
pgo-scheduler-image: check-go-vars
	go install pgo-scheduler/pgo-scheduler.go
	mv $(GOBIN)/pgo-scheduler ./bin/pgo-scheduler/
	docker build -t pgo-scheduler -f $(PGO_BASEOS)/Dockerfile.pgo-scheduler.$(PGO_BASEOS) .
	docker tag pgo-scheduler $(PGO_IMAGE_PREFIX)/pgo-scheduler:$(PGO_IMAGE_TAG)
all:
	make postgres-operator-image
	make pgo-apiserver-image
	make pgo-scheduler-image
	make pgo
	make pgo-backrest-repo-image
	make pgo-backrest-image
	make pgo-rmdata-image
	make pgo-backrest-restore-image
	make pgo-lspvc-image
	make pgo-load-image
	make pgo-sqlrunner-image
push:
	docker push $(PGO_IMAGE_PREFIX)/postgres-operator:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-apiserver:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-backrest-repo:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-backrest-restore:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-lspvc:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-load:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-rmdata:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-sqlrunner:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-backrest:$(PGO_IMAGE_TAG)
	docker push $(PGO_IMAGE_PREFIX)/pgo-scheduler:$(PGO_IMAGE_TAG)
pull:
	docker pull $(PGO_IMAGE_PREFIX)/postgres-operator:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-apiserver:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-backrest-repo:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-backrest-restore:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-lspvc:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-load:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-rmdata:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-sqlrunner:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-backrest:$(PGO_IMAGE_TAG)
	docker pull $(PGO_IMAGE_PREFIX)/pgo-scheduler:$(PGO_IMAGE_TAG)
release:	check-go-vars
	make macpgo
	make winpgo
	rm -rf $(RELTMPDIR) $(RELFILE) 
	mkdir $(RELTMPDIR)
	cp -r $(PGOROOT)/examples $(RELTMPDIR)
	cp -r $(PGOROOT)/deploy $(RELTMPDIR)
	cp -r $(PGOROOT)/conf $(RELTMPDIR)
	cp $(GOBIN)/pgo $(RELTMPDIR)
	cp $(GOBIN)/pgo-mac $(RELTMPDIR)
	cp $(GOBIN)/pgo.exe $(RELTMPDIR)
	cp $(GOBIN)/expenv $(RELTMPDIR)
	cp $(GOBIN)/expenv-mac $(RELTMPDIR)
	cp $(GOBIN)/expenv.exe $(RELTMPDIR)
	cp $(PGOROOT)/examples/pgo-bash-completion $(RELTMPDIR)
	tar czvf $(RELFILE) -C $(RELTMPDIR) .
default:
	all

