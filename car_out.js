const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({region: 'us-east-1'});
// Load the AWS SDK for Node.js

exports.handler = (event,context,callback) => {
    const queryParams = {
        TableName: 'CarParking',
        IndexName: 'car_state-car_in_time-index',
        KeyConditionExpression: 'car_state = :hkey and car_in_time < :rkey',
        ExpressionAttributeValues: {
            ':hkey':'car_in',
            ':rkey': Date.now()
        }
    };

    const email = {
        Message: 'Sorry,you need to pay for parking fee',
        TopicArn: 'arn:aws:sns:us-east-1:160071257600:car_in'
    };


    if (event.payment === true){
        ddb.query(queryParams,function(err,data){
            console.log(data)
            let updateParams = {
                TableName: 'CarParking',
                Key: { car_no : data.Items[0].car_no,car_in_time:data.Items[0].car_in_time},
                UpdateExpression: 'set #a = :car_state ,  #b = :car_out_time',
                ConditionExpression: '#a = :car_in',
                ExpressionAttributeNames: {'#a' : 'car_state','#b':'car_out_time'},
                ExpressionAttributeValues: {
                    ':car_state' : 'car_out',
                    ':car_in' : 'car_in',
                    ':car_out_time':Date.now()
                }
            }
            ddb.update(updateParams).promise().then((data)=>{
                console.log(data)
            });
        })
    }else {
        return  new AWS.SNS({apiVersion: '2010-03-31'}).publish(email).promise();
    }



};
