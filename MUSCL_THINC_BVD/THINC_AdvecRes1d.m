function res = THINC_AdvecRes1d(qi,flux,dflux,S,dx)
%
% A pure THINC-BVD implementation for scalar advection Equations 
%
%% THINC reconstruction
% Constants parameters
Beta_s=1.1; Beta_l=2.0; epsilon=1E-20;

% Initial Arrays      
% qi = q;  % : q_{ j }^{n},
qim1 = circshift(qi,+1); % : q_{j-1}^{n},
qip1 = circshift(qi,-1); % : q_{j+1}^{n}.

% Coeficients
qmin = min(cat(3,qim1,qip1),[],3);
qmax = max(cat(3,qim1,qip1),[],3)-qmin;
theta= sign(qip1-qim1); %theta(theta==0)=1;
C = (qi-qmin+epsilon)./(qmax+epsilon);
B = exp(Beta_s*theta.*(2*C-1));
A = (B/cosh(Beta_s)-1)/tanh(Beta_s);

% q_{i+1/2}^{-} and q_{i-1/2}^{+} reconstructions for Beta_s
qiph_s = qmin + 0.5*qmax.*(1+theta.*(tanh(Beta_s)+A)./(1+A*tanh(Beta_s)));
qimh_s = qmin + 0.5*qmax.*(1+theta.*A);

B = exp(Beta_l*theta.*(2*C-1));
A = (B/cosh(Beta_l)-1)/tanh(Beta_l);

% q_{i+1/2}^{-} and q_{i-1/2}^{+} reconstructions for Beta_l
qiph_l = qmin + 0.5*qmax.*(1+theta.*(tanh(Beta_l)+A)./(1+A*tanh(Beta_l)));
qimh_l = qmin + 0.5*qmax.*(1+theta.*A);

% Compute total boundary variations TBV for each cell
TBV_s = abs(circshift(qiph_s,+1)-qimh_s)+abs(qiph_s-circshift(qimh_s,-1));
TBV_l = abs(circshift(qiph_l,+1)-qimh_l)+abs(qiph_l-circshift(qimh_l,-1));

%% 3. BVD Algorithm
condition = TBV_l < TBV_s;
qiph_s(condition)=qiph_l(condition); qL=circshift(qiph_s,0);
qimh_s(condition)=qimh_l(condition); qR=circshift(qimh_s,-1);

% Debug
% qL=circshift(qiph_W,0);
% qR=circshift(qimh_W,-1);

%% Compute Lax-Friedrichs numerical flux and update solution
LF = 0.5*(flux(qL)+flux(qR)-abs(dflux(qi)).*(qR-qL)); % Lax friedrichs flux
res = (LF-circshift(LF,1))/dx - S(qi); % L = df(q)/dx + S(q).