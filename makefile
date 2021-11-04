NUM_ATTRIBUTES ?= 9
NUM_EXAMPLES ?= 698
RINGSIZE ?= 64
DEBUG ?= True
BATCH ?= 128
N_ITERATIONS ?= 100
APPROX ?= 5

init:
	@echo "Installing dependencies..."
	sudo apt-get install automake build-essential git libboost-dev libboost-thread-dev libntl-dev libsodium-dev libssl-dev libtool m4 python3 texinfo yasm git
	@echo "Downloading MP-SPDZ binaries..."
	git clone https://github.com/data61/MP-SPDZ.git
	@echo "OK. Building MP-SPDZ"
	cd MP-SPDZ && $(MAKE) -j$(nproc) mpir
	cd MP-SPDZ && $(MAKE) -j$(nproc) rep-ring
	cd MP-SPDZ &&./Scripts/setup-ssl.sh 3

client:
	test -s ./MP-SPDZ/replicated-ring-party.x|| { echo "It seems like MP-SPDZ has not yet been compiled! Run make init first. Exiting..."; exit 1; }
	rm -f ./MP-SPDZ/Persistence/*
	@echo "Setting up client-side code"
	sed 's/§NUMATTR§/'$(NUM_ATTRIBUTES)'/g; s/§NUMEX§/'$(NUM_EXAMPLES)'/g' ./create_shares.src > ./MP-SPDZ/Programs/Source/create_shares.mpc
	@echo "OK. Compiling..."
	python ./MP-SPDZ/compile.py -R $(RINGSIZE) create_shares.mpc
	@echo "Done building client code."

server:
	test -s ./MP-SPDZ/replicated-ring-party.x|| { echo "It seems like MP-SPDZ has not yet been compiled! Run make init first. Exiting..."; exit 1; }
	rm -f ./MP-SPDZ/Persistence/*
	@echo "Setting up server-side code"
	sed 's/§NUMATTR§/'$(NUM_ATTRIBUTES)'/g; s/§NUMEX§/'$(NUM_EXAMPLES)'/g; s/§DEBUG_FLAG§/'$(DEBUG)'/g; s/§BATCHSIZE§/'$(BATCH)'/g; s/§NUMITER§/'$(N_ITERATIONS)'/g;s/§APPROX_TYPE§/'$(APPROX)'/g' ./logistic_regression.src > ./MP-SPDZ/Programs/Source/logistic_regression.mpc
	@echo "OK. Compiling..."
	python ./MP-SPDZ/compile.py -R $(RINGSIZE) logistic_regression.mpc
	@echo "Done building server code."

tf:
	sed 's/§NUMATTR§/'$(NUM_ATTRIBUTES)'/g; s/§NUMEX§/'$(NUM_EXAMPLES)'/g; s/§DEBUG_FLAG§/'$(DEBUG)'/g; s/§BATCHSIZE§/'$(BATCH)'/g; s/§NUMITER§/'$(N_ITERATIONS)'/g;s/§APPROX_TYPE§/'$(APPROX)'/g' ./test.src > ./MP-SPDZ/Programs/Source/test.mpc
	@echo "OK. Compiling..."
	python ./MP-SPDZ/compile.py -R $(RINGSIZE) test.mpc
	@echo "Done building client code."

runclient:
	cd MP-SPDZ && ./Scripts/ring.sh -R $(RINGSIZE) create_shares

runserver:
	cd MP-SPDZ && ./Scripts/ring.sh -R $(RINGSIZE) logistic_regression

runtf:
	cd MP-SPDZ && ./Scripts/ring.sh -R $(RINGSIZE) test

cleanstate:
	rm -f ./MP-SPDZ/Persistence/*
	rm -f ./MP-SPDZ/Player-Data/Input-P*
clean:
	rm -rf ./MP-SPDZ/
	rm -f ./*.mpc