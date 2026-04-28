Using the connector with an anonymous server
--------------------------------------------

.. important::

   This page applies to Odoo connectors installed after March 2026.
   See `this page <../odoo-before-march-2026/using-the-connector-in-frepple.html>`_ for
   Odoo connectors installed before March 2026.

Overview
~~~~~~~~

Odoo users can use the frePPLe recommendation screen without a dedicated frePPLe instance.
When this feature is enabled, your Odoo data is sent to an anonymous frePPLe server at
https://odoo.frepple.com, a plan is generated on that server, and the recommendations are
sent back to your Odoo instance. No dedicated frePPLe installation or subscription is required.

Data privacy
~~~~~~~~~~~~

We understand that sending business data to an external server is a sensitive matter.
Here is what happens with your data when using the anonymous server:

* Your data is used **exclusively** to generate the plan. It is not used for any other purpose.
* Your data is **deleted immediately** after the plan has been generated and the recommendations
  have been sent back to Odoo.
* **No backups, snapshots, or copies** of your data are made at any point during the process.
* We do **not** retain, analyze, or share your data in any way beyond the plan generation.

Configuration
~~~~~~~~~~~~~

To enable this feature, go to the frePPLe settings in Odoo and set the following parameters:

* **frePPLe server**: ``https://odoo.frepple.com``
* **Webtoken key**: ``anonymous_web_service``

Your Odoo instance must also be accessible from the internet. The anonymous server needs to
reach your Odoo instance to send the recommendations back. Local or private network
installations that are not exposed to the internet will not work with this feature.

Cost and availability
~~~~~~~~~~~~~~~~~~~~~

Hosting and operating the anonymous server has an ongoing cost for frePPLe. This service is
currently provided **free of charge**, but this may change in the future depending on the
server load and usage. Any changes to the pricing will be communicated in advance.
