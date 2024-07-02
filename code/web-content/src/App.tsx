/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 */

import './styles/App.css'
import { withAuthenticator } from '@aws-amplify/ui-react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import NotFound from './routes/not-found';
import Home from './routes/home';
import Sessions from './routes/instances';
import Templates from './routes/templates';
import Instances from './routes/instances';
import TopNavBar from './components/topnavbar';

function App() {
  return (
    <>
      <BrowserRouter>
        <TopNavBar />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/index.html" element={<Home />} />
          <Route path="/my-sessions" element={<Sessions />} />
          <Route path="/my-instances" element={<Instances />} />
          <Route path="/my-templates" element={<Templates />} />
          <Route path="/admin-sessions" element={<Sessions />} />
          <Route path="/admin-instances" element={<Instances />} />
          <Route path="/admin-templates" element={<Templates />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </>
  );

};

export default withAuthenticator(App, {
  hideSignUp: true,
});