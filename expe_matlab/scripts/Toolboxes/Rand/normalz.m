function [z] = normalz(p,mu,sigma)

if nargin < 3
    sigma = 1;
end
if nargin < 2
    mu = 0;
end
if nargin < 1
    error('Wrong input argument list.');
end

z = mu+sqrt(2)*sigma*erfinv(2*p-1);

end