% 
% /******************************************************************************
% 
% This program, "NCDM", the associated MATLAB scripts and all 
% provided data, are copyright (C) 2013-2014 Andrew R. Cohen and Paul
% M. B. Vitanyi.  All rights reserved.
% 
% This program uses bzip2 compressor as a static library.
% See the file SRC\C\bz2static\LICENSE.txt for details on that software.
% 
% This software may be referenced as:
% 
% A.R.Cohen and P.M.B. Vitanyi, "Normalized Compression Distance of Multisets 
% with Applications," IEEE Transactions on Pattern Analysis and Machine 
% Intelligence. 2014. In Press. Also arXiv:1212.5711.  
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 
% 2. The origin of this software must not be misrepresented; you must 
%    not claim that you wrote the original software.  If you use this 
%    software in a product, an acknowledgment in the product 
%    documentation would be appreciated but is not required.
% 
% 3. Altered source versions must be plainly marked as such, and must
%    not be misrepresented as being the original software.
% 
% 4. The name of the author may not be used to endorse or promote 
%    products derived from this software without specific prior written 
%    permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
% OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
% GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% Andrew R. Cohen acohen@coe.drexel.edu
% Paul M. B. Vitanyi Paul.Vitanyi@cwi.nl
% NCDM  version 1.0 of 13 March 2013
% NCDM  version 2.0 (release) November 2014
% 
% ******************************************************************************/



ofile='testNISTn5r100.mat'

szpool=matlabpool('size');
if szpool==0
    %     myCluster = parcluster('local');
    %     myCluster.NumWorkers = 32;  % 'Modified' property now TRUE
    %     saveProfile(myCluster);
    matlabpool(32)
end
NLABS=matlabpool('size')

%get multisets!
load('trainNISTn5r100.mat');

IMDIM=28*28;

% read test images
file = fopen('t10k-labels.idx1-ubyte','rb');
labels=fread(file);
fclose(file);
% labels[9] onwards are 1 byte values (0..9) specifying digits in test file
file = fopen('t10k-images.idx3-ubyte','rb');
images=fread(file);
fclose(file);

start = 17;
Classify=[];
for i=1:NLABS:10000
    
    tic
    Trellis=[];
    for j=0:NLABS-1
        
        ixx = i+j-1;
        ixx=min(ixx,9999);
        start = 17 + (ixx)*IMDIM;
        im1 = images([start:start+IMDIM-1]);
        
        %     start = start + IMDIM;
        label = labels(8+ixx+1);
        
        nt=[];
        nt.idxTrue=label;
        im1=PreProcessImage(im1);
        nt.bCount = getCount(im1);
        nt.im=im1;
        nt.i=i+j-1;
        Trellis=[Trellis nt];
    end % j
    
    spmd
        cc = GoClassify(Trellis(labindex),Training,NCDTraining,labindex);
    end

    tt=toc;
    tt=round(tt*10)/10;
    
    for j=1:NLABS
        if length(Classify)>=10000
            continue
        end
        res=cc{j};
        res(2)=i+j-1;
        Classify=[Classify;res];
        accuracy = sum(Classify(:,1))/length(Classify(:,1));
        
        fprintf(1,'%d : %.2f, %s time=%f\n',i+j-1,accuracy,mat2str(res(1:3)),tt);
        if mod(i+j-1,200)==0
            save(ofile,'Classify','NCARDINALITY','NREPLICATES','bUsedTraining');
        end
    end
end

save(ofile,'Classify','NCARDINALITY','NREPLICATES','bUsedTraining');