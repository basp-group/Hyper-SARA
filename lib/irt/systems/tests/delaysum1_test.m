% delaysum1_test.m
% Steve Schmitt

Nh = 10000;
Nx = 100;
Nm = 500;
Ny = Nh;

h = randn(Nh,1);
d = round(randn(Nx,Nm)*100);
x = randn(Nx,1);

tic;
yt = delaysum1_mex('delaysum1,forw,thr',...
	single(h),...
	single(d),...
	int32(8),...
	single(x),...
	int32(Ny),...
	int32(0));
t1 = toc;

tic;
y = delaysum1_mex('delaysum1,forw',...
	single(h),...
	single(d),...
	int32(1),...
	single(x),...
	int32(Ny), ...
	int32(0));
t2 = toc;

printm('forward:\n threaded time = %f\n non-threaded time = %f\n speedup = %f\n\n',t1,t2,t2/t1);
if any(y ~= yt)
	fprintf('****** BUT THREADED != NON-THREADED ******\n');
end

tic;
b = delaysum1_mex('delaysum1,back',...
	single(h),...
	single(d),...
	int32(1),...
	single(y), ...
	int32(0));
t3 = toc;

tic;
bt = delaysum1_mex('delaysum1,back,thr',...
	single(h),...
	single(d),...
	int32(8),...
	single(y),...
	int32(0));
t4 = toc;

printm('back:\n threaded time = %f\n non-threaded time = %f\n speedup = %f\n\n',t4,t3,t3/t4);

if any(b ~= bt)
	fprintf('****** BUT THREADED != NON-THREADED ******\n');
end