const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({region: 'us-east-1'});
exports.handler = (event) => {
    let queryParams = {
        TableName: 'CarParking',
        IndexName: 'car_state-car_in_time-index',
        KeyConditionExpression: 'car_state = :hkey and car_in_time < :rkey',
        ExpressionAttributeValues: {
            ':hkey':'car_in',
            ':rkey': Date.now()
        }
    };

    let saveParams = {
        TableName: 'CarParking',
        Item: {
            'car_state': event.state,
            'car_no': event.car_no,
            'car_in_time': Date.now()
        }
    };

    const email = {
        Message: 'Sorry, the parking is full now',
        TopicArn: 'arn:aws:sns:us-east-1:160071257600:car_in_email'
    };

    const maxNum = 5;
    ddb.query(queryParams, function(err, data) {
        if(data.Count < maxNum){
            ddb.put(saveParams).promise().then(()=>{
                console.log(`car:${event.car_no}in`)
            });
        }else {
            return  new AWS.SNS({apiVersion: '2010-03-31'}).publish(email).promise();
        }
    });
};
