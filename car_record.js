const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({region: 'us-east-1'});
// Load the AWS SDK for Node.js
exports.handler = (event,context,callback) => {
    const params = {
        TableName: 'CarRecord',
        Item: {
            'car_state': event.state,
            'car_no': event.car_no,
            'time': Date.now()
        }
    };
    console.log(params);
    ddb.put(params).promise().then(()=>{
        console.log(`${event.state} record:${event.car_no}`)
    });
};