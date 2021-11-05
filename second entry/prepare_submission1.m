% prepare_submission: This file illustrates how to prepare an entry
% for the PhysioNet/CinC 2018 Challenge.  It first trains a classifier
% for each record in the training set, then runs the classifiers over
% each record in both the training and test sets. The results from the
% training set are used to calculate scores (the average AUROC and
% average AUPRC), and the results from the test set are saved as .vec
% files for submission to PhysioNet.
%
% Written by Mohammad Ghassemi and Benjamin Moody, 2018

% PLEASE NOTE: The script assumes that you have downloaded the data, and is meant
%             to be run from the directory containing the '/training' and '/test'
%             subdirectories

clear all

% STEP 0: Get information on the subject files
[headers_tr, headers_te] = get_file_info;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: For  the first 900 training subjects, let's build 90 models.One
% model per 10 records
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
X_tr=[];Y_tr=[];
for i = 1:10%length(headers_tr)
    display('--------------------------------------------------')
    display(['Working on Subject ' num2str(i) '/' num2str(length(headers_tr))])
    
    [X_tr1 Y_tr1]=data_to_train_classifier(headers_tr{i});
    X_tr=[X_tr; X_tr1];
    Y_tr=[Y_tr; Y_tr1];
end
data=X_tr;groups=Y_tr;
clear X_tr Y_tr X_tr1 Y_tr1;

groups(groups==0)=2; 
groups=categorical(groups);

%This command instructs the bidirectional LSTM layer to map the input time series into 50 features
%and then prepares the output for the fully connected layer. Finally, specify two classes by including
% a fully connected layer of size 2, followed by a softmax layer and a classification layer.
layers = [ ...
    sequenceInputLayer(24)
    bilstmLayer(50,'OutputMode','last')
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer
    ];

%Specify the training options for the classifier.

options = trainingOptions('adam', ...
    'MaxEpochs',50, ...
    'MiniBatchSize', 5, ...
    'InitialLearnRate', 0.01, ...
    'Verbose',false);                                                                  

netM = trainNetwork(data,groups,layers,options); % 90 such models are built for 10 records each.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 2: Apply the models to the remaining training set, and check performance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Initialize scoring function
score2018();
window_step=6000;
for i = 901:994%length(headers_tr)
        display('---------------------------------------------------------------')
        display(['Evaluating Models on Training Subject ' num2str(i) '/' num2str(length(headers_tr))])
        
        data = parse_header(headers_tr{i});
        arousal      = load(data.arousal_location); arousal = arousal.data.arousals;
        
        % If there are no arousals, skip this subject...
        if length(unique(arousal)) == 1
            display('No arousals detected, skipping subject')
            continue;
        end
        [predictions_NN, n_samples]= data_to_run_classifier_hybrid(headers_tr{i});
       % The output of 90 LSTM models are fed to 9 quadratic discriminant
       % models which are built using the predictions generated by each LSTM for training records.
        files1 = dir(); files1 = {files1.name};
        models1 = find(contains(files1,'hmodel'));
        
        for n = 1:length(models1)
                % loading models
                load(files1{models1(n)});
        end
                % generate the probability vectors
                 predictions1 = QDset1.predictFcn(predictions_NN(:,[1:10]));
                 predictions2 = QDset2.predictFcn(predictions_NN(:,[11:20]));
                 predictions3 = QDset3.predictFcn(predictions_NN(:,[21:30]));
                 predictions4 = QDset4.predictFcn(predictions_NN(:,[31:40]));
                 predictions5 = QDset5.predictFcn(predictions_NN(:,[41:50]));
                 predictions6 = QDset6.predictFcn(predictions_NN(:,[51:60]));
                 predictions7 = QDset7.predictFcn(predictions_NN(:,[61:70]));
                 predictions8 = QDset8.predictFcn(predictions_NN(:,[71:80]));
                 predictions9 = QDset9.predictFcn(predictions_NN(:,[81:90]));
                
                pred_LD=[ predictions1  predictions2  predictions3  predictions4  predictions5 predictions6 predictions7 predictions8 predictions9];
                %avg_pred=mean(pred_LD,2);

                 % Compute average of the predictions.
                avg_pred=0;
                for nn=1:9
                         j=length(pred_LD);
                         avg_pred = avg_pred + (pred_LD(:,nn) - avg_pred) / (j+1);
                
                end
                
                pred = mean(avg_pred)*ones(n_samples,1);
                
                for j = 1:length(avg_pred)
                        paste_in = (j-1)*window_step+1 : j*window_step;
                        pred(paste_in) = avg_pred(j)*ones(window_step,1);
                end
                
        % Calculate AUPRC and AUROC scores
        [auprc_g, auroc_g, auprc_r, auroc_r] = score2018(arousal, pred');

        display(['Gross AUROC (so far): ' num2str(auroc_g)]);
        display(['Gross AUPRC (so far): ' num2str(auprc_g)]);        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 3: Apply the model to the testing set, and save .vec files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
window_step=6000;
for i = 1:length(headers_te)
        display('---------------------------------------------------------------')
        display(['Scoring Test Subject ' num2str(i) '/' num2str(length(headers_te))])

        [predictions_NN, n_samples]= data_to_run_classifier_hybrid(headers_te{i});
       
        files1 = dir(); files1 = {files1.name};
        models1 = find(contains(files1,'hmodel'));
        
        for n = 1:length(models1)
                % loading models
                load(files1{models1(n)});
        end
                % generate the probability vectors
                 predictions1 = QDset1.predictFcn(predictions_NN(:,[1:10]));
                 predictions2 = QDset2.predictFcn(predictions_NN(:,[11:20]));
                 predictions3 = QDset3.predictFcn(predictions_NN(:,[21:30]));
                 predictions4 = QDset4.predictFcn(predictions_NN(:,[31:40]));
                 predictions5 = QDset5.predictFcn(predictions_NN(:,[41:50]));
                 predictions6 = QDset6.predictFcn(predictions_NN(:,[51:60]));
                 predictions7 = QDset7.predictFcn(predictions_NN(:,[61:70]));
                 predictions8 = QDset8.predictFcn(predictions_NN(:,[71:80]));
                 predictions9 = QDset9.predictFcn(predictions_NN(:,[81:90]));
                
                 pred_LD=[ predictions1  predictions2  predictions3  predictions4  predictions5 predictions6 predictions7 predictions8 predictions9];
                
                 % Compute average of the predictions.
                avg_pred=0;
                for nn=1:9
                         j=length(pred_LD);
                         avg_pred = avg_pred + (pred_LD(:,nn) - avg_pred) / (j+1);
                end
                
                predictions = mean(avg_pred)*ones(n_samples,1);
                
                for j = 1:length(avg_pred)
                        paste_in = (j-1)*window_step+1 : j*window_step;
                        predictions(paste_in) = avg_pred(j)*ones(window_step,1);
                end
                
       % Save the predictions for submission to the challenge
        display(['Saving predictions'])
        [~, recbase, ~] = fileparts(headers_te{i});
        fileID = fopen([recbase '.vec'], 'w');
        fprintf(fileID, '%.3f\n', predictions);
        fclose(fileID);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 4: Generate a zip file for submission to PhysioNet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Delete any files if they existed previously
delete('entry.zip');
% Note: this will not package any sub-directories!
zip('entry.zip', {'*.m', '*.c', '*.mat', '*.vec', '*.txt', '*.sh'});