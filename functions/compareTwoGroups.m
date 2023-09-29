function [p_val,testType, stats, graph1] = compareTwoGroups(group1,group2, paired)
% Compare two data sets. First, test for normality to determine if a parametric or nonparametric
% test needs to be used. Perform a relevant statistical test.
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

%   Input arguments:
% - group 1 and group 2: two samples that will be compared (matrices)
% - paired: paired for 0; non-paired for 1

% - It is noteworthy that comparing std to test for equal variance to determine
% the test type is not always ideal.

[h(1), ~, ~] = swtest(group1);
[h(2), ~, ~] = swtest(group1);

var1 = var(group1,1);
var2 = var(group2,1);

if paired == 1 % if paired
    if h(1) + h(2) == 0 % if both groups follow a normal distribution (1: reject "not nomal")
        [~, p_val, ~, ~] =ttest(group1,group2); 
        testType = 'Paired t-test' ; 
    else % if one of the groups do not follow a normal distribution
        [p_val, ~, stats] = signrank(group1,group2); 
        testType = 'Wilcoxon signed rank test';   
    end    
else % two-sample (independent sample) test
    if h(1) + h(2) == 0 % if both groups follow a normal distribution (1: reject "not nomal")
        if  var1/var2 >1/4 || var1/var2 < 4 % equal variance
            [~, p_val, ~, stats] =ttest2(group1,group2); % two-sample t-test
            testType = 'Two-sample t-test' ;
        else % unequal variance
           [~, p_val, ~, stats]  = ttest2(group1, group2, 'varType', 'unequal');
           testType = 'Two-sample t-test with unequal variances' ;
        end
    else
        x = NaN(max(length(group1),length(group2)),2);
        x(1:length(group1),1) = group1;
        x(1:length(group2),2) = group2;
        [p_val, ~, stats] = kruskalwallis(x); % conduct a non parametric test instead
        testType = 'Kruskal-Wallis Test' ; % similar to Mann-whiteny but takes more than 2 groups
    end
end
     
graph1 = figure; set(gcf,"Position", [500         100         190         200]);
[~, ~, ~, ~, ~] = al_goodplot(group1, 1);
[~, ~, ~, ~, ~] = al_goodplot(group2, 2);
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off;
end